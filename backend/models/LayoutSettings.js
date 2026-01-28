import mongoose from "mongoose";

// All available layout sections - must match Flutter's LayoutSection enum
const LAYOUT_SECTIONS = [
  "progressChart",
  "monthlyProgress",
  "habitGrid",
  "overview",
  "calendar",
  "overallProgress",
  "topHabits",
];

const layoutSettingsSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    unique: true,
  },
  columnsDesktop: {
    type: Number,
    default: 3,
    min: 1,
    max: 6,
  },
  columnsTablet: {
    type: Number,
    default: 2,
    min: 1,
    max: 4,
  },
  visibleSections: {
    type: Map,
    of: Boolean,
    default: () => {
      const map = new Map();
      LAYOUT_SECTIONS.forEach((section) => map.set(section, true));
      return map;
    },
  },
  sectionOrder: {
    type: [String],
    default: LAYOUT_SECTIONS,
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

export { LAYOUT_SECTIONS };
export default LayoutSettings;
