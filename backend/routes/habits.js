import express from "express";
import Habit from "../models/Habit.js";
import LayoutSettings from "../models/LayoutSettings.js";
import auth from "../middleware/auth.js";

const router = express.Router();

// All routes require authentication
router.use(auth);

// Helper to transform habit for response
const transformHabit = (habit) => ({
  id: habit._id,
  name: habit.name,
  goalDays: habit.goalDays,
  completedDays: Object.fromEntries(habit.completedDays || new Map()),
});

// @route   GET /api/habits
// @desc    Get all habits for the authenticated user
// @access  Private
router.get("/", async (req, res) => {
  try {
    const habits = await Habit.find({ userId: req.userId }).sort({
      createdAt: 1,
    });
    const transformedHabits = habits.map(transformHabit);
    res.json({ habits: transformedHabits });
  } catch (error) {
    console.error("Get habits error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// @route   POST /api/habits
// @desc    Create a new habit
// @access  Private
router.post("/", async (req, res) => {
  try {
    const { name, goalDays } = req.body;

    const habit = new Habit({
      userId: req.userId,
      name,
      goalDays,
      completedDays: new Map(),
    });

    await habit.save();

    res.status(201).json({
      message: "Habit created successfully",
      habit: transformHabit(habit),
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

// @route   DELETE /api/habits/:id
// @desc    Delete a habit
// @access  Private
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const habit = await Habit.findOneAndDelete({ _id: id, userId: req.userId });

    if (!habit) {
      return res.status(404).json({ message: "Habit not found" });
    }

    res.json({ message: "Habit deleted successfully" });
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

    const habit = await Habit.findOne({ _id: id, userId: req.userId });

    if (!habit) {
      return res.status(404).json({ message: "Habit not found" });
    }

    // Toggle the day
    const currentValue = habit.completedDays.get(date) || false;
    habit.completedDays.set(date, !currentValue);
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

// @route   POST /api/habits/sync
// @desc    Sync all habits (bulk update)
// @access  Private
router.post("/sync", async (req, res) => {
  try {
    const { habits } = req.body;

    // Delete all existing habits for this user
    await Habit.deleteMany({ userId: req.userId });

    // Create new habits
    const newHabits = habits.map((habit) => ({
      userId: req.userId,
      name: habit.name,
      goalDays: habit.goalDays,
      completedDays: new Map(Object.entries(habit.completedDays || {})),
    }));

    const savedHabits = await Habit.insertMany(newHabits);
    const transformedHabits = savedHabits.map(transformHabit);

    res.json({
      message: "Habits synced successfully",
      habits: transformedHabits,
    });
  } catch (error) {
    console.error("Sync habits error:", error);
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

export default router;
