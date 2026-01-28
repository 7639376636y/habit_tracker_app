import mongoose from "mongoose";

const layoutSettingsSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    unique: true,
  },
  columnsDesktop: {
    type: Number,
    default: 2,
  },
  columnsTablet: {
    type: Number,
    default: 1,
  },
  visibleSections: {
    type: Map,
    of: Boolean,
    default: () => new Map(),
  },
  sectionOrder: {
    type: [String],
    default: [
      "habitGrid",
      "overallProgress",
      "topHabits",
      "progressChart",
      "monthlyPie",
    ],
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

layoutSettingsSchema.pre("save", function (next) {
  this.updatedAt = Date.now();
  next();
});

const LayoutSettings = mongoose.model("LayoutSettings", layoutSettingsSchema);

export default LayoutSettings;
