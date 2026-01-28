import express from "express";
import Habit, { HABIT_CATEGORIES, FREQUENCY_TYPES } from "../models/Habit.js";
import HabitCompletion from "../models/HabitCompletion.js";
import LayoutSettings from "../models/LayoutSettings.js";
import User from "../models/User.js";
import auth from "../middleware/auth.js";

const router = express.Router();

// All routes require authentication
router.use(auth);

// Helper to get completed days from HabitCompletion collection
const getCompletedDays = async (habitId) => {
  const completions = await HabitCompletion.find({
    habitId,
    completed: true,
  })
    .select("date")
    .lean();

  const map = {};
  completions.forEach((c) => {
    map[c.date] = true;
  });
  return map;
};

// Helper to transform habit for response (async version)
const transformHabitAsync = async (habit) => {
  // Get completions from separate collection
  const completedDays = await getCompletedDays(habit._id);

  return {
    id: habit._id.toString(),
    name: habit.name,
    description: habit.description || "",
    category: habit.category,
    color: habit.color,
    icon: habit.icon || "",
    goalDays: habit.goalDays,
    completedDays,
    frequency: {
      type: habit.frequency?.type || "daily",
      daysOfWeek: habit.frequency?.daysOfWeek || [],
      timesPerWeek: habit.frequency?.timesPerWeek || 7,
    },
    reminder: habit.reminder
      ? {
          enabled: habit.reminder.enabled,
          time: habit.reminder.time,
          days: habit.reminder.days || [],
        }
      : { enabled: false, time: "09:00", days: [] },
    streak: {
      current: habit.streaks?.current || 0,
      longest: habit.streaks?.longest || 0,
      lastCompletedDate: habit.streaks?.lastCompletedDate || null,
    },
    notes: habit.notes || [],
    isArchived: habit.isArchived || false,
    sortOrder: habit.sortOrder || 0,
    createdAt: habit.createdAt,
    updatedAt: habit.updatedAt,
  };
};

// Helper to transform habit for response (sync version - uses embedded data)
// DEPRECATED: Use transformHabitAsync when possible
const transformHabit = (habit) => ({
  id: habit._id.toString(),
  name: habit.name,
  description: habit.description || "",
  category: habit.category,
  color: habit.color,
  icon: habit.icon || "",
  goalDays: habit.goalDays,
  completedDays: Object.fromEntries(habit.completedDays || new Map()),
  frequency: {
    type: habit.frequency?.type || "daily",
    daysOfWeek: habit.frequency?.daysOfWeek || [],
    timesPerWeek: habit.frequency?.timesPerWeek || 7,
  },
  reminder: habit.reminder
    ? {
        enabled: habit.reminder.enabled,
        time: habit.reminder.time,
        days: habit.reminder.days || [],
      }
    : { enabled: false, time: "09:00", days: [] },
  streak: {
    current: habit.streaks?.current || 0,
    longest: habit.streaks?.longest || 0,
    lastCompletedDate: habit.streaks?.lastCompletedDate || null,
  },
  notes: habit.notes || [],
  isArchived: habit.isArchived || false,
  sortOrder: habit.sortOrder || 0,
  createdAt: habit.createdAt,
  updatedAt: habit.updatedAt,
});

// Helper to check habit limit based on user's limits
const checkHabitLimit = async (userId) => {
  const user = await User.findById(userId);
  if (!user) throw new Error("User not found");

  // Use user's stored limits (set based on subscription plan)
  const maxHabits = user.limits?.maxHabits ?? 10; // Default to 10 if not set

  const habitCount = await Habit.countDocuments({
    userId,
    isDeleted: { $ne: true },
    isArchived: { $ne: true },
  });

  return {
    canCreate: maxHabits === -1 || habitCount < maxHabits, // -1 means unlimited
    current: habitCount,
    max: maxHabits,
    plan: user.subscription?.plan || "free",
  };
};

// Helper to update streak (DEPRECATED - use updateStreakFromCompletions)
const updateStreak = (habit, date) => {
  const today = new Date(date);
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toISOString().split("T")[0];

  const wasCompletedYesterday = habit.completedDays.get(yesterdayStr);
  const isCompleted = habit.completedDays.get(date);

  if (isCompleted) {
    if (wasCompletedYesterday || habit.streaks.current === 0) {
      habit.streaks.current += 1;
    } else {
      habit.streaks.current = 1;
    }
    habit.streaks.longest = Math.max(
      habit.streaks.longest,
      habit.streaks.current,
    );
    habit.streaks.lastCompletedDate = today;
  } else {
    // Check if streak should be reset
    if (habit.streaks.lastCompletedDate) {
      const lastCompleted = new Date(habit.streaks.lastCompletedDate);
      const daysDiff = Math.floor(
        (today - lastCompleted) / (1000 * 60 * 60 * 24),
      );
      if (daysDiff > 1) {
        habit.streaks.current = 0;
      }
    }
  }

  return habit;
};

// Helper to update streak from HabitCompletion collection
const updateStreakFromCompletions = async (habit) => {
  const completions = await HabitCompletion.find({
    habitId: habit._id,
    completed: true,
  })
    .select("date")
    .sort({ date: -1 })
    .lean();

  if (completions.length === 0) {
    habit.streaks.current = 0;
    habit.streaks.lastCompletedDate = null;
    return habit;
  }

  const sortedDates = completions
    .map((c) => c.date)
    .sort()
    .reverse();
  habit.streaks.lastCompletedDate = sortedDates[0];

  // Calculate current streak
  const today = new Date().toISOString().split("T")[0];
  const yesterday = new Date(Date.now() - 86400000).toISOString().split("T")[0];

  // Only count if completed today or yesterday
  if (sortedDates[0] !== today && sortedDates[0] !== yesterday) {
    habit.streaks.current = 0;
    return habit;
  }

  let currentStreak = 1;
  for (let i = 1; i < sortedDates.length; i++) {
    const prevDate = new Date(sortedDates[i - 1]);
    const currDate = new Date(sortedDates[i]);
    const diffDays = Math.round((prevDate - currDate) / (1000 * 60 * 60 * 24));

    if (diffDays === 1) {
      currentStreak++;
    } else {
      break;
    }
  }

  habit.streaks.current = currentStreak;
  habit.streaks.longest = Math.max(habit.streaks.longest, currentStreak);

  return habit;
};

// @route   GET /api/habits/categories
// @desc    Get available habit categories
// @access  Private
router.get("/categories", async (req, res) => {
  res.json({ categories: HABIT_CATEGORIES, frequencyTypes: FREQUENCY_TYPES });
});

// @route   GET /api/habits/limits
// @desc    Get user's habit limits based on subscription
// @access  Private
router.get("/limits", async (req, res) => {
  try {
    const limits = await checkHabitLimit(req.userId);
    res.json(limits);
  } catch (error) {
    console.error("Get limits error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   GET /api/habits
// @desc    Get all habits for the authenticated user
// @access  Private
router.get("/", async (req, res) => {
  try {
    const { includeArchived, includeDeleted } = req.query;

    const query = { userId: req.userId };

    // By default, exclude deleted habits
    if (includeDeleted !== "true") {
      query.isDeleted = { $ne: true };
    }

    // By default, exclude archived habits unless requested
    if (includeArchived !== "true") {
      query.isArchived = { $ne: true };
    }

    const habits = await Habit.find(query).sort({ sortOrder: 1, createdAt: 1 });

    // Transform all habits with completions from separate collection
    const transformedHabits = await Promise.all(
      habits.map((habit) => transformHabitAsync(habit)),
    );

    // Get limits info
    const limits = await checkHabitLimit(req.userId);

    res.json({
      habits: transformedHabits,
      limits,
    });
  } catch (error) {
    console.error("Get habits error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   GET /api/habits/archived
// @desc    Get archived habits
// @access  Private
router.get("/archived", async (req, res) => {
  try {
    const habits = await Habit.find({
      userId: req.userId,
      isArchived: true,
      isDeleted: { $ne: true },
    }).sort({ updatedAt: -1 });

    const transformedHabits = await Promise.all(
      habits.map((habit) => transformHabitAsync(habit)),
    );

    res.json({ habits: transformedHabits });
  } catch (error) {
    console.error("Get archived habits error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   GET /api/habits/layout
// @desc    Get layout settings
// @access  Private
router.get("/layout", async (req, res) => {
  try {
    let settings = await LayoutSettings.findOne({ userId: req.userId });

    if (!settings) {
      settings = new LayoutSettings({ userId: req.userId });
      await settings.save();
    }

    res.json({
      layoutSettings: {
        columnsDesktop: settings.columnsDesktop,
        columnsTablet: settings.columnsTablet,
        visibleSections: Object.fromEntries(
          settings.visibleSections || new Map(),
        ),
        sectionOrder: settings.sectionOrder,
      },
    });
  } catch (error) {
    console.error("Get layout settings error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   PUT /api/habits/layout
// @desc    Update layout settings
// @access  Private
router.put("/layout", async (req, res) => {
  try {
    const { columnsDesktop, columnsTablet, visibleSections, sectionOrder } =
      req.body;

    let settings = await LayoutSettings.findOne({ userId: req.userId });

    if (!settings) {
      settings = new LayoutSettings({ userId: req.userId });
    }

    if (columnsDesktop !== undefined) settings.columnsDesktop = columnsDesktop;
    if (columnsTablet !== undefined) settings.columnsTablet = columnsTablet;
    if (visibleSections)
      settings.visibleSections = new Map(Object.entries(visibleSections));
    if (sectionOrder) settings.sectionOrder = sectionOrder;

    await settings.save();

    res.json({
      message: "Layout settings updated",
      layoutSettings: {
        columnsDesktop: settings.columnsDesktop,
        columnsTablet: settings.columnsTablet,
        visibleSections: Object.fromEntries(
          settings.visibleSections || new Map(),
        ),
        sectionOrder: settings.sectionOrder,
      },
    });
  } catch (error) {
    console.error("Update layout settings error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// ========== Completion Statistics Routes ==========
// These must be before /:id routes to avoid being matched as habit IDs

// @route   GET /api/habits/completions/range
// @desc    Get all completions for user within date range (for calendar view)
// @access  Private
router.get("/completions/range", async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    if (!startDate || !endDate) {
      return res
        .status(400)
        .json({ message: "startDate and endDate are required" });
    }

    const completions = await HabitCompletion.find({
      userId: req.userId,
      date: { $gte: startDate, $lte: endDate },
      completed: true,
    })
      .select("habitId date completed value")
      .lean();

    // Group by habit for easier processing
    const grouped = {};
    completions.forEach((c) => {
      const habitId = c.habitId.toString();
      if (!grouped[habitId]) {
        grouped[habitId] = [];
      }
      grouped[habitId].push(c.date);
    });

    res.json({
      completions,
      groupedByHabit: grouped,
      totalCount: completions.length,
    });
  } catch (error) {
    console.error("Get completions range error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   GET /api/habits/stats/monthly
// @desc    Get monthly completion statistics
// @access  Private
router.get("/stats/monthly", async (req, res) => {
  try {
    const { year, month } = req.query;

    const startDate = `${year}-${String(month).padStart(2, "0")}-01`;
    const endDate = `${year}-${String(month).padStart(2, "0")}-31`;

    // Get all habits for user
    const habits = await Habit.find({
      userId: req.userId,
      isDeleted: { $ne: true },
      isArchived: { $ne: true },
    }).select("_id name color");

    // Get completions for the month
    const completions = await HabitCompletion.find({
      userId: req.userId,
      date: { $gte: startDate, $lte: endDate },
      completed: true,
    })
      .select("habitId date")
      .lean();

    // Calculate stats
    const stats = habits.map((habit) => {
      const habitCompletions = completions.filter(
        (c) => c.habitId.toString() === habit._id.toString(),
      );
      return {
        habitId: habit._id,
        name: habit.name,
        color: habit.color,
        completedDays: habitCompletions.length,
        dates: habitCompletions.map((c) => c.date),
      };
    });

    res.json({
      year: parseInt(year),
      month: parseInt(month),
      stats,
      totalCompletions: completions.length,
    });
  } catch (error) {
    console.error("Get monthly stats error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   POST /api/habits
// @desc    Create a new habit
// @access  Private
router.post("/", async (req, res) => {
  try {
    // Check habit limit
    const limits = await checkHabitLimit(req.userId);
    if (!limits.canCreate) {
      return res.status(403).json({
        message: `You've reached your habit limit (${limits.max}). Upgrade your plan to create more habits.`,
        limits,
      });
    }

    const {
      name,
      description,
      category,
      color,
      icon,
      goalDays,
      frequency,
      reminder,
    } = req.body;

    // Get current max sortOrder
    const lastHabit = await Habit.findOne({ userId: req.userId })
      .sort({ sortOrder: -1 })
      .select("sortOrder");
    const sortOrder = (lastHabit?.sortOrder || 0) + 1;

    // Normalize category to lowercase (model expects lowercase)
    const normalizedCategory = category ? category.toLowerCase() : "custom";

    const habit = new Habit({
      userId: req.userId,
      name,
      description: description || "",
      category: normalizedCategory,
      color: color || "#6366F1",
      icon: icon || "",
      goalDays: goalDays || 30,
      frequency: frequency || { type: "daily" },
      reminder: reminder || { enabled: false },
      completedDays: new Map(),
      sortOrder,
    });

    await habit.save();

    res.status(201).json({
      message: "Habit created successfully",
      habit: transformHabit(habit),
      limits: await checkHabitLimit(req.userId),
    });
  } catch (error) {
    console.error("Create habit error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   PUT /api/habits/:id
// @desc    Update a habit
// @access  Private
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      description,
      category,
      color,
      icon,
      goalDays,
      frequency,
      reminder,
      sortOrder,
    } = req.body;

    const habit = await Habit.findOne({
      _id: id,
      userId: req.userId,
      isDeleted: { $ne: true },
    });

    if (!habit) {
      return res.status(404).json({ message: "Habit not found" });
    }

    // Update fields if provided
    if (name !== undefined) habit.name = name;
    if (description !== undefined) habit.description = description;
    if (category !== undefined) habit.category = category;
    if (color !== undefined) habit.color = color;
    if (icon !== undefined) habit.icon = icon;
    if (goalDays !== undefined) habit.goalDays = goalDays;
    if (frequency !== undefined) habit.frequency = frequency;
    if (reminder !== undefined) habit.reminder = reminder;
    if (sortOrder !== undefined) habit.sortOrder = sortOrder;

    await habit.save();

    res.json({
      message: "Habit updated successfully",
      habit: transformHabit(habit),
    });
  } catch (error) {
    console.error("Update habit error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   POST /api/habits/:id/archive
// @desc    Archive a habit (soft archive)
// @access  Private
router.post("/:id/archive", async (req, res) => {
  try {
    const { id } = req.params;
    const habit = await Habit.findOne({
      _id: id,
      userId: req.userId,
      isDeleted: { $ne: true },
    });

    if (!habit) {
      return res.status(404).json({ message: "Habit not found" });
    }

    habit.isArchived = true;
    await habit.save();

    res.json({
      message: "Habit archived successfully",
      habit: transformHabit(habit),
    });
  } catch (error) {
    console.error("Archive habit error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   POST /api/habits/:id/restore
// @desc    Restore an archived habit
// @access  Private
router.post("/:id/restore", async (req, res) => {
  try {
    const { id } = req.params;
    const habit = await Habit.findOne({
      _id: id,
      userId: req.userId,
      isDeleted: { $ne: true },
    });

    if (!habit) {
      return res.status(404).json({ message: "Habit not found" });
    }

    habit.isArchived = false;
    await habit.save();

    res.json({
      message: "Habit restored successfully",
      habit: transformHabit(habit),
    });
  } catch (error) {
    console.error("Restore habit error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   DELETE /api/habits/:id
// @desc    Soft delete a habit
// @access  Private
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { permanent } = req.query;

    const habit = await Habit.findOne({ _id: id, userId: req.userId });

    if (!habit) {
      return res.status(404).json({ message: "Habit not found" });
    }

    if (permanent === "true") {
      // Permanent delete
      await Habit.findByIdAndDelete(id);
      res.json({ message: "Habit permanently deleted" });
    } else {
      // Soft delete
      habit.isDeleted = true;
      habit.deletedAt = new Date();
      await habit.save();
      res.json({ message: "Habit deleted successfully" });
    }
  } catch (error) {
    console.error("Delete habit error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   POST /api/habits/:id/toggle
// @desc    Toggle a day's completion status for a habit
// @access  Private
router.post("/:id/toggle", async (req, res) => {
  try {
    const { date } = req.body;
    const { id } = req.params;

    const habit = await Habit.findOne({
      _id: id,
      userId: req.userId,
      isDeleted: { $ne: true },
    });

    if (!habit) {
      return res.status(404).json({ message: "Habit not found" });
    }

    // Toggle completion using HabitCompletion collection
    const completion = await HabitCompletion.toggleCompletion(
      habit._id,
      req.userId,
      date,
    );

    // Update streak based on new completion status
    await updateStreakFromCompletions(habit);
    await habit.save();

    res.json({
      message: "Day toggled successfully",
      habit: await transformHabitAsync(habit),
      completion: {
        date: completion.date,
        completed: completion.completed,
      },
    });
  } catch (error) {
    console.error("Toggle day error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   POST /api/habits/:id/note
// @desc    Add a note to a habit
// @access  Private
router.post("/:id/note", async (req, res) => {
  try {
    const { id } = req.params;
    const { date, content } = req.body;

    const habit = await Habit.findOne({
      _id: id,
      userId: req.userId,
      isDeleted: { $ne: true },
    });

    if (!habit) {
      return res.status(404).json({ message: "Habit not found" });
    }

    habit.notes.push({ date: new Date(date), content });
    await habit.save();

    res.json({
      message: "Note added successfully",
      habit: transformHabit(habit),
    });
  } catch (error) {
    console.error("Add note error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   PUT /api/habits/reorder
// @desc    Reorder habits
// @access  Private
router.put("/reorder", async (req, res) => {
  try {
    const { habitIds } = req.body; // Array of habit IDs in new order

    const updatePromises = habitIds.map((id, index) =>
      Habit.findOneAndUpdate(
        { _id: id, userId: req.userId },
        { sortOrder: index },
      ),
    );

    await Promise.all(updatePromises);

    res.json({ message: "Habits reordered successfully" });
  } catch (error) {
    console.error("Reorder habits error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   POST /api/habits/sync
// @desc    Sync all habits (bulk update) - for initial migration
// @access  Private
router.post("/sync", async (req, res) => {
  try {
    const { habits } = req.body;

    // Check limit before syncing
    const user = await User.findById(req.userId);
    const maxHabits = user.limits?.maxHabits ?? 10;

    if (maxHabits !== -1 && habits.length > maxHabits) {
      return res.status(403).json({
        message: `Cannot sync ${habits.length} habits. Your plan allows ${maxHabits} habits.`,
        maxAllowed: maxHabits,
      });
    }

    // Soft delete all existing habits for this user
    await Habit.updateMany(
      { userId: req.userId },
      { isDeleted: true, deletedAt: new Date() },
    );

    // Create new habits
    const newHabits = habits.map((habit, index) => ({
      userId: req.userId,
      name: habit.name,
      description: habit.description || "",
      category: habit.category ? habit.category.toLowerCase() : "custom",
      color: habit.color || "#6366F1",
      icon: habit.icon || "",
      goalDays: habit.goalDays || 30,
      frequency: habit.frequency || { type: "daily" },
      completedDays: new Map(Object.entries(habit.completedDays || {})),
      sortOrder: index,
    }));

    const savedHabits = await Habit.insertMany(newHabits);
    const transformedHabits = savedHabits.map(transformHabit);

    res.json({
      message: "Habits synced successfully",
      habits: transformedHabits,
      limits: await checkHabitLimit(req.userId),
    });
  } catch (error) {
    console.error("Sync habits error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// ========== Completion-specific routes ==========

// @route   GET /api/habits/:id/completions
// @desc    Get completions for a specific habit within date range
// @access  Private
router.get("/:id/completions", async (req, res) => {
  try {
    const { id } = req.params;
    const { startDate, endDate } = req.query;

    // Verify habit belongs to user
    const habit = await Habit.findOne({
      _id: id,
      userId: req.userId,
      isDeleted: { $ne: true },
    });

    if (!habit) {
      return res.status(404).json({ message: "Habit not found" });
    }

    let query = { habitId: id, completed: true };

    // Add date range filter if provided
    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = startDate;
      if (endDate) query.date.$lte = endDate;
    }

    const completions = await HabitCompletion.find(query)
      .select("date completed value notes mood completedAt")
      .sort({ date: -1 })
      .lean();

    res.json({ completions });
  } catch (error) {
    console.error("Get completions error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

export default router;
