/**
 * Migration script to move completedDays from Habit documents
 * to the separate HabitCompletion collection.
 *
 * Run this script once to migrate existing data:
 *   node scripts/migrateCompletions.js
 */

import mongoose from "mongoose";
import dotenv from "dotenv";
import Habit from "../models/Habit.js";
import HabitCompletion from "../models/HabitCompletion.js";

dotenv.config();

const MONGODB_URI =
  process.env.MONGODB_URI || "mongodb://localhost:27017/habit_tracker";

async function migrateCompletions() {
  try {
    console.log("Connecting to MongoDB...");
    await mongoose.connect(MONGODB_URI);
    console.log("Connected successfully!\n");

    // Get all habits that haven't been migrated
    const habits = await Habit.find({
      completionsMigrated: { $ne: true },
    }).setOptions({ includeDeleted: true });

    console.log(`Found ${habits.length} habits to migrate.\n`);

    let totalMigrated = 0;
    let totalErrors = 0;

    for (const habit of habits) {
      try {
        const completedDays = habit.completedDays;

        if (!completedDays || completedDays.size === 0) {
          // No completions to migrate, just mark as migrated
          habit.completionsMigrated = true;
          await habit.save();
          console.log(`✓ Habit "${habit.name}" - No completions to migrate`);
          continue;
        }

        // Convert Map to object for migration
        const completedDaysObj = Object.fromEntries(completedDays);

        // Migrate to HabitCompletion collection
        const count = await HabitCompletion.migrateFromEmbedded(
          habit._id,
          habit.userId,
          completedDaysObj,
        );

        // Mark habit as migrated
        habit.completionsMigrated = true;
        await habit.save();

        totalMigrated += count;
        console.log(`✓ Habit "${habit.name}" - Migrated ${count} completions`);
      } catch (error) {
        totalErrors++;
        console.error(`✗ Habit "${habit.name}" - Error: ${error.message}`);
      }
    }

    console.log("\n========================================");
    console.log("Migration Complete!");
    console.log(`Total completions migrated: ${totalMigrated}`);
    console.log(`Total errors: ${totalErrors}`);
    console.log("========================================\n");

    // Optionally, clear old completedDays data after successful migration
    // Uncomment the following to clean up embedded data:
    /*
    console.log("Cleaning up embedded completedDays data...");
    await Habit.updateMany(
      { completionsMigrated: true },
      { $set: { completedDays: new Map() } }
    );
    console.log("Cleanup complete!");
    */
  } catch (error) {
    console.error("Migration failed:", error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log("Disconnected from MongoDB.");
  }
}

// Run the migration
migrateCompletions();
