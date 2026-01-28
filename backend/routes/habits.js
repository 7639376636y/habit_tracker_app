import express from "express";
import Habit, { HABIT_CATEGORIES, FREQUENCY_TYPES } from "../models/Habit.js";
import LayoutSettings from "../models/LayoutSettings.js";
import User from "../models/User.js";
import auth from "../middleware/auth.js";

const router = express.Router();

// All routes require authentication
router.use(auth);

// Helper to transform habit for response
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
    current: habit.streak?.current || 0,
    longest: habit.streak?.longest || 0,
    lastCompletedDate: habit.streak?.lastCompletedDate || null,
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

// Helper to update streak
const updateStreak = (habit, date) => {
  const today = new Date(date);
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toISOString().split("T")[0];

  const wasCompletedYesterday = habit.completedDays.get(yesterdayStr);
  const isCompleted = habit.completedDays.get(date);

  if (isCompleted) {
    if (wasCompletedYesterday || habit.streak.current === 0) {
      habit.streak.current += 1;
    } else {
      habit.streak.current = 1;
    }
    habit.streak.longest = Math.max(habit.streak.longest, habit.streak.current);
    habit.streak.lastCompletedDate = today;
  } else {
    // Check if streak should be reset
    if (habit.streak.lastCompletedDate) {
      const lastCompleted = new Date(habit.streak.lastCompletedDate);
      const daysDiff = Math.floor(
        (today - lastCompleted) / (1000 * 60 * 60 * 24),
      );
      if (daysDiff > 1) {
        habit.streak.current = 0;
      }
    }
  }

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
    const transformedHabits = habits.map(transformHabit);

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

    res.json({ habits: habits.map(transformHabit) });
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
    const { name, goalDays } = req.body;
    const { id } = req.params;

    const habit = await Habit.findOne({ _id: id, userId: req.userId });

    if (!habit) {
      return res.status(404).json({ message: "Habit not found" });
    }

    habit.name = name || habit.name;
    habit.goalDays = goalDays || habit.goalDays;
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

    // Toggle the day
    const currentValue = habit.completedDays.get(date) || false;
    habit.completedDays.set(date, !currentValue);

    // Update streak
    updateStreak(habit, date);

    await habit.save();

    res.json({
      message: "Day toggled successfully",
      habit: transformHabit(habit),
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

export default router;
