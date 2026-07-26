import { describe, expect, it } from "vitest";
import { featureFlags } from "../lib/config/feature-flags";

describe("garde-fou du trading réel", () => {
  it("reste désactivé au niveau du code", () => {
    expect(featureFlags.realTradingEnabled).toBe(false);
  });
});
