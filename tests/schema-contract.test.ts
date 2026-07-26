import { describe, expect, it } from "vitest";
import type { ModeOperation } from "../lib/database.types";

describe("contrat des modes d’opération", () => {
  it("conserve les trois modes prévus", () => {
    const modes: ModeOperation[] = ["PAPIER_AUTONOME", "PAPIER_VALIDATION", "REEL_VALIDATION"];
    expect(modes).toHaveLength(3);
  });
});
