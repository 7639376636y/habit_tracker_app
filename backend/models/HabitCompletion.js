import mongoose from "mongoose";

/**
 * HabitCompletion Model
 *
 * Stores habit completion records separately from the Habit document.
 * This is more scalable than embedding completedDays inside Habit.
 *
 * Benefits:
 * - Habit document stays small and fast
 * - Can query completions by date range efficiently
 * - Easier to aggregate stats and generate reports
 * - Can add metadata (notes, mood, time of completion)
 * - MongoDB document size limit won't be an issue
 */

const habitCompletionSchema = new mongoose.Schema(
  {
    // References
    habitId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Habit",
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    // Date of completion (stored as YYYY-MM-DD string for easy querying)
    date: {
      type: String,
      required: true,
      match: [/^\d{4}-\d{2}-\d{2}$/, "Date must be in YYYY-MM-DD format"],
    },

    // Completion status
    completed: {
      type: Boolean,
      default: true,
    },

    // Optional metadata for future features
    completedAt: {
      type: Date,
      default: Date.now,
    },
    notes: {
      type: String,
      maxlength: 500,
      default: null,
    },
    mood: {
      type: String,
      enum: ["great", "good", "okay", "bad", "terrible", null],
      default: null,
    },

    // For partial completions (e.g., "3 glasses of water out of 8")
    value: {
      type: Number,
      default: 1,
    },
    targetValue: {
      type: Number,
      default: 1,
    },
  },
  {
    timestamps: true,
  },
);

// Compound index for efficient queries
// Ensures one record per habit per date
habitCompletionSchema.index({ habitId: 1, date: 1 }, { unique: true });

// Index for user's completions by date range
habitCompletionSchema.index({ userId: 1, date: 1 });

// Index for getting all completions in a month
habitCompletionSchema.index({ userId: 1, date: 1, completed: 1 });

// Static method to get completions for a habit within date range
habitCompletionSchema.statics.getCompletionsForHabit = async function (
  habitId,
  startDate,
  endDate,
) {
  return this.find({
    habitId,
    date: { $gte: startDate, $lte: endDate },
    completed: true,
  })
    .select("date completed value notes mood")
    .lean();
};

// Static method to get all completions for a user within date range
habitCompletionSchema.statics.getCompletionsForUser = async function (
  userId,
  startDate,
  endDate,
) {
  return this.find({
    userId,
    date: { $gte: startDate, $lte: endDate },
    completed: true,
  })
    .select("habitId date completed value")
    .lean();
};

// Static method to toggle completion
habitCompletionSchema.statics.toggleCompletion = async function (
  habitId,
  userId,
  date,
) {
  const existing = await this.findOne({ habitId, date });

  if (existing) {
    // Toggle the completion status
    existing.completed = !existing.completed;
    existing.completedAt = existing.completed ? new Date() : null;
    await existing.save();
    return existing;
  } else {
    // Create new completion record
    const completion = new this({
      habitId,
      userId,
      date,
      completed: true,
      completedAt: new Date(),
    });
    await completion.save();
    return completion;
  }
};

// Static method to get completion map for a habit (for backwards compatibility)
habitCompletionSchema.statics.getCompletedDaysMap = async function (habitId) {
  const completions = await this.find({
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

// Static method to migrate data from embedded completedDays
habitCompletionSchema.statics.migrateFromEmbedded = async function (
  habitId,
  userId,
  completedDaysMap,
) {
  const operations = [];

  for (const [date, completed] of Object.entries(completedDaysMap)) {
    if (completed) {
      operations.push({
        updateOne: {
          filter: { habitId, date },
          update: {
            $setOnInsert: {
              habitId,
              userId,
              date,
              completed: true,
              completedAt: new Date(),
            },
          },
          upsert: true,
        },
      });
    }
  }

  if (operations.length > 0) {
    await this.bulkWrite(operations);
  }

  return operations.length;
};

const HabitCompletion = mongoose.model(
  "HabitCompletion",
  habitCompletionSchema,
);

export default HabitCompletion;
