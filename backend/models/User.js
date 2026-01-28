import mongoose from "mongoose";
import bcrypt from "bcryptjs";

// Subscription plans for SaaS
const PLANS = {
  FREE: "free",
  BASIC: "basic",
  PRO: "pro",
  ENTERPRISE: "enterprise",
};

const userSchema = new mongoose.Schema(
  {
    // Basic info
    name: {
      type: String,
      required: [true, "Name is required"],
      trim: true,
      maxlength: [100, "Name cannot exceed 100 characters"],
    },
    email: {
      type: String,
      required: [true, "Email is required"],
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    password: {
      type: String,
      required: [true, "Password is required"],
      minlength: 6,
      select: false, // Don't return password by default
    },

    // Profile
    avatar: {
      type: String,
      default: null,
    },
    timezone: {
      type: String,
      default: "UTC",
    },
    locale: {
      type: String,
      default: "en",
    },

    // Subscription & Billing (SaaS ready)
    subscription: {
      plan: {
        type: String,
        enum: Object.values(PLANS),
        default: PLANS.FREE,
      },
      status: {
        type: String,
        enum: ["active", "inactive", "cancelled", "past_due", "trialing"],
        default: "active",
      },
      trialEndsAt: {
        type: Date,
        default: null,
      },
      currentPeriodStart: {
        type: Date,
        default: null,
      },
      currentPeriodEnd: {
        type: Date,
        default: null,
      },
      stripeCustomerId: {
        type: String,
        default: null,
        index: true,
      },
      stripeSubscriptionId: {
        type: String,
        default: null,
      },
    },

    // Usage limits based on plan
    limits: {
      maxHabits: {
        type: Number,
        default: 10, // Free plan limit
      },
      maxCategories: {
        type: Number,
        default: 3,
      },
      canExportData: {
        type: Boolean,
        default: false,
      },
      canUseReminders: {
        type: Boolean,
        default: false,
      },
      canUseAnalytics: {
        type: Boolean,
        default: false,
      },
    },

    // Preferences
    preferences: {
      theme: {
        type: String,
        enum: ["light", "dark", "system"],
        default: "system",
      },
      notifications: {
        email: { type: Boolean, default: true },
        push: { type: Boolean, default: true },
        reminderTime: { type: String, default: "09:00" },
      },
      weekStartsOn: {
        type: Number,
        enum: [0, 1], // 0 = Sunday, 1 = Monday
        default: 1,
      },
    },

    // Account status
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    emailVerificationToken: {
      type: String,
      default: null,
    },
    passwordResetToken: {
      type: String,
      default: null,
    },
    passwordResetExpires: {
      type: Date,
      default: null,
    },

    // Soft delete
    isDeleted: {
      type: Boolean,
      default: false,
      index: true,
    },
    deletedAt: {
      type: Date,
      default: null,
    },

    // Metadata
    lastLoginAt: {
      type: Date,
      default: null,
    },
    loginCount: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true, // Adds createdAt and updatedAt
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

// Indexes for performance
userSchema.index({ email: 1, isDeleted: 1 });
userSchema.index({ "subscription.plan": 1, isActive: 1 });
userSchema.index({ createdAt: -1 });

// Virtual for full name (if we add firstName/lastName later)
userSchema.virtual("displayName").get(function () {
  return this.name;
});

// Hash password before saving
userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();

  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Update limits based on plan
userSchema.pre("save", function (next) {
  if (this.isModified("subscription.plan")) {
    const planLimits = {
      free: {
        maxHabits: 10,
        maxCategories: 3,
        canExportData: false,
        canUseReminders: false,
        canUseAnalytics: false,
      },
      basic: {
        maxHabits: 25,
        maxCategories: 10,
        canExportData: true,
        canUseReminders: true,
        canUseAnalytics: false,
      },
      pro: {
        maxHabits: 100,
        maxCategories: 50,
        canExportData: true,
        canUseReminders: true,
        canUseAnalytics: true,
      },
      enterprise: {
        maxHabits: -1,
        maxCategories: -1,
        canExportData: true,
        canUseReminders: true,
        canUseAnalytics: true,
      }, // -1 = unlimited
    };
    this.limits = planLimits[this.subscription.plan] || planLimits.free;
  }
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Check if user can add more habits
userSchema.methods.canAddHabit = async function (currentHabitCount) {
  if (this.limits.maxHabits === -1) return true; // Unlimited
  return currentHabitCount < this.limits.maxHabits;
};

// Update last login
userSchema.methods.updateLoginInfo = async function () {
  this.lastLoginAt = new Date();
  this.loginCount += 1;
  await this.save();
};

// Soft delete
userSchema.methods.softDelete = async function () {
  this.isDeleted = true;
  this.deletedAt = new Date();
  this.isActive = false;
  await this.save();
};

// Query helpers - exclude deleted users by default
userSchema.pre(/^find/, function (next) {
  if (!this.getOptions().includeDeleted) {
    this.where({ isDeleted: { $ne: true } });
  }
  next();
});

const User = mongoose.model("User", userSchema);

export { PLANS };
export default User;
