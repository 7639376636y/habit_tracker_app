import express from "express";
import jwt from "jsonwebtoken";
import User from "../models/User.js";
import Habit from "../models/Habit.js";
import auth from "../middleware/auth.js";

const router = express.Router();

// Generate JWT Token
const generateToken = (userId) =>
  jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: "30d" });

// Transform user for response
const transformUser = (user, habitCount = 0) => ({
  id: user._id,
  name: user.name,
  email: user.email,
  avatar: user.avatar,
  timezone: user.timezone,
  subscription: {
    plan: user.subscription?.plan || "free",
    status: user.subscription?.status || "active",
  },
  limits: {
    maxHabits: user.limits?.maxHabits || 10,
    currentHabits: habitCount,
  },
  preferences: user.preferences || {},
});

// @route   POST /api/auth/signup
// @desc    Register a new user
// @access  Public
router.post("/signup", async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // Validation
    if (!name || !email || !password) {
      return res.status(400).json({ message: "All fields are required" });
    }

    if (password.length < 6) {
      return res
        .status(400)
        .json({ message: "Password must be at least 6 characters" });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res
        .status(400)
        .json({ message: "User already exists with this email" });
    }

    // Create new user with default settings
    const user = new User({
      name,
      email,
      password,
      subscription: {
        plan: "free",
        status: "active",
      },
    });
    await user.save();

    // Update login info
    await user.updateLoginInfo();

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      message: "User created successfully",
      token,
      user: transformUser(user, 0),
    });
  } catch (error) {
    console.error("Signup error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// @route   POST /api/auth/signin
// @desc    Authenticate user & get token
// @access  Public
router.post("/signin", async (req, res) => {
  try {
    const { email, password } = req.body;

    // Check if user exists (include password for comparison)
    const user = await User.findOne({ email }).select("+password");
    if (!user) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    // Update login info
    await user.updateLoginInfo();

    // Get habit count
    const habitCount = await Habit.countDocuments({
      userId: user._id,
      isDeleted: { $ne: true },
    });

    // Generate token
    const token = generateToken(user._id);

    res.json({
      message: "Login successful",
      token,
      user: transformUser(user, habitCount),
    });
  } catch (error) {
    console.error("Signin error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// @route   GET /api/auth/me
// @desc    Get current user
// @access  Private
router.get("/me", auth, async (req, res) => {
  try {
    const habitCount = await Habit.countDocuments({
      userId: req.user._id,
      isDeleted: { $ne: true },
    });

    res.json({
      user: transformUser(req.user, habitCount),
    });
  } catch (error) {
    res.status(500).json({ message: "Server error" });
  }
});

export default router;
