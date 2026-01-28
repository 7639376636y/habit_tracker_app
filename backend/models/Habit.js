import mongoose from "mongoose";

const habitSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  name: {
    type: String,
    required: [true, "Habit name is required"],
    trim: true,
  },
  goalDays: {
    type: Number,
    required: [true, "Goal days is required"],
    min: 1,
  },
  completedDays: {
    type: Map,
    of: Boolean,
    default: () => new Map(),
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

// Update the updatedAt field on save
habitSchema.pre("save", function (next) {
  this.updatedAt = Date.now();
  next();
});

const Habit = mongoose.model("Habit", habitSchema);

export default Habit;
