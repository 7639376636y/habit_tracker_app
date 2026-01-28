import mongoose from "mongoose";

// Habit categories for organization
const HABIT_CATEGORIES = {
  HEALTH: "health",
  FITNESS: "fitness",
  PRODUCTIVITY: "productivity",
  MINDFULNESS: "mindfulness",
  LEARNING: "learning",
  FINANCE: "finance",
  SOCIAL: "social",
  CREATIVITY: "creativity",
  CUSTOM: "custom",
  OTHER: "other",
};

// Frequency types
const FREQUENCY_TYPES = {
  DAILY: "daily",
  WEEKLY: "weekly",
  SPECIFIC_DAYS: "specific_days",
  X_TIMES_PER_WEEK: "x_times_per_week",
  X_TIMES_PER_MONTH: "x_times_per_month",
};

const habitSchema = new mongoose.Schema(
  {
    // Owner
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    // Basic info
    name: {
      type: String,
      required: [true, "Habit name is required"],
      trim: true,
      maxlength: [100, "Habit name cannot exceed 100 characters"],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [500, "Description cannot exceed 500 characters"],
      default: null,
    },

    // Goal settings
    goalDays: {
      type: Number,
      required: [true, "Goal days is required"],
      min: [1, "Goal must be at least 1 day"],
      max: [365, "Goal cannot exceed 365 days"],
    },
    frequency: {
      type: {
        type: String,
        enum: Object.values(FREQUENCY_TYPES),
        default: FREQUENCY_TYPES.DAILY,
      },
      daysOfWeek: {
        type: [Number], // 0-6 for Sun-Sat
        default: [0, 1, 2, 3, 4, 5, 6],
      },
      timesPerPeriod: {
        type: Number,
        default: 1,
      },
    },

    // Appearance
    category: {
      type: String,
      enum: Object.values(HABIT_CATEGORIES),
      default: HABIT_CATEGORIES.CUSTOM,
      index: true,
    },
    color: {
      type: String,
      default: "#6366F1",
      match: [/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/, "Invalid color format"],
    },
    icon: {
      type: String,
      default: "check_circle",
    },

    // Tracking data - DEPRECATED: Use HabitCompletion collection instead
    // Kept for backwards compatibility during migration
    completedDays: {
      type: Map,
      of: Boolean,
      default: () => new Map(),
    },

    // Flag to indicate if completions have been migrated to separate collection
    completionsMigrated: {
      type: Boolean,
      default: false,
    },

    // Streak tracking
    streaks: {
      current: {
        type: Number,
        default: 0,
      },
      longest: {
        type: Number,
        default: 0,
      },
      lastCompletedDate: {
        type: String,
        default: null,
      },
    },

    // Reminders (for premium users)
    reminder: {
      enabled: {
        type: Boolean,
        default: false,
      },
      time: {
        type: String, // HH:mm format
        default: "09:00",
      },
      days: {
        type: [Number], // Days to remind
        default: [1, 2, 3, 4, 5, 6, 0],
      },
    },

    // Notes/Journal entries
    notes: [
      {
        date: {
          type: String,
          required: true,
        },
        content: {
          type: String,
          maxlength: 1000,
        },
        createdAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],

    // Status
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    isPaused: {
      type: Boolean,
      default: false,
    },
    pausedAt: {
      type: Date,
      default: null,
    },

    // Archive/Delete
    isArchived: {
      type: Boolean,
      default: false,
      index: true,
    },
    archivedAt: {
      type: Date,
      default: null,
    },
    isDeleted: {
      type: Boolean,
      default: false,
      index: true,
    },
    deletedAt: {
      type: Date,
      default: null,
    },

    // Ordering
    sortOrder: {
      type: Number,
      default: 0,
    },

    // Timestamps
    startDate: {
      type: Date,
      default: Date.now,
    },
    endDate: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

// Compound indexes for common queries
habitSchema.index({ userId: 1, isDeleted: 1, isArchived: 1 });
habitSchema.index({ userId: 1, category: 1 });
habitSchema.index({ userId: 1, sortOrder: 1 });
habitSchema.index({ userId: 1, createdAt: -1 });

// Virtual for completion percentage
habitSchema.virtual("completionPercentage").get(function () {
  if (!this.completedDays || this.goalDays === 0) return 0;
  const completedCount = [...this.completedDays.values()].filter(
    (v) => v,
  ).length;
  return Math.min(100, Math.round((completedCount / this.goalDays) * 100));
});

// Virtual for completed count
habitSchema.virtual("completedCount").get(function () {
  if (!this.completedDays) return 0;
  return [...this.completedDays.values()].filter((v) => v).length;
});

// Update streak on save
habitSchema.pre("save", function (next) {
  if (this.isModified("completedDays")) {
    this._updateStreaks();
  }
  next();
});

// Method to update streaks
habitSchema.methods._updateStreaks = function () {
  if (!this.completedDays || this.completedDays.size === 0) {
    this.streaks.current = 0;
    return;
  }

  // Sort dates and calculate streaks
  const sortedDates = [...this.completedDays.entries()]
    .filter(([, completed]) => completed)
    .map(([date]) => date)
    .sort()
    .reverse();

  if (sortedDates.length === 0) {
    this.streaks.current = 0;
    return;
  }

  this.streaks.lastCompletedDate = sortedDates[0];

  // Calculate current streak
  let currentStreak = 1;
  const today = new Date().toISOString().split("T")[0];
  const yesterday = new Date(Date.now() - 86400000).toISOString().split("T")[0];

  // Only count if completed today or yesterday
  if (sortedDates[0] !== today && sortedDates[0] !== yesterday) {
    this.streaks.current = 0;
  } else {
    for (let i = 1; i < sortedDates.length; i++) {
      const prevDate = new Date(sortedDates[i - 1]);
      const currDate = new Date(sortedDates[i]);
      const diffDays = (prevDate - currDate) / (1000 * 60 * 60 * 24);

      if (diffDays === 1) {
        currentStreak++;
      } else {
        break;
      }
    }
    this.streaks.current = currentStreak;
  }

  // Update longest streak if needed
  if (this.streaks.current > this.streaks.longest) {
    this.streaks.longest = this.streaks.current;
  }
};

// Soft delete
habitSchema.methods.softDelete = async function () {
  this.isDeleted = true;
  this.deletedAt = new Date();
  await this.save();
};

// Archive
habitSchema.methods.archive = async function () {
  this.isArchived = true;
  this.archivedAt = new Date();
  await this.save();
};

// Restore from archive
habitSchema.methods.restore = async function () {
  this.isArchived = false;
  this.archivedAt = null;
  await this.save();
};

// Query helpers - exclude deleted habits by default
habitSchema.pre(/^find/, function (next) {
  if (!this.getOptions().includeDeleted) {
    this.where({ isDeleted: { $ne: true } });
  }
  next();
});

const Habit = mongoose.model("Habit", habitSchema);

export { HABIT_CATEGORIES, FREQUENCY_TYPES };
export default Habit;
