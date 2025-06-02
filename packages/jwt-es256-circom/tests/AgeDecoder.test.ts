import { WitnessTester } from "circomkit";
import { circomkit } from "./common";
import { encodeClaims } from "../src/utils";

describe("AgeClaimDecoder", () => {
  let circuit: WitnessTester<["claims", "claimLengths"], ["decodedClaims"]>;

  const maxClaimsLength = 128;
  const maxClaims = 2;

  before(async () => {
    circuit = await circomkit.WitnessTester("AgeClaimDecoder", {
      file: "claim-decoder",
      template: "AgeClaimDecoder",
      params: [maxClaimsLength],
      recompile: true,
    });
    console.log("#constraints:", await circuit.getConstraintCount());
  });

  it("It should decode raw claims with padding correctly", async () => {
    const inputs = ["WyI4STBWclR0QnpNdlFFSmxmV2hqS2FBIiwicm9jX2JpcnRoZGF5IiwiMTA0MDYwNSJd"];

    // const expectedOutputs = inputs.map((b64) => Buffer.from(b64, "base64").toString("utf8"));

    const { claimArray, claimLengths } = encodeClaims(inputs, maxClaims, maxClaimsLength);

    const witness = await circuit.calculateWitness({
      claims: claimArray[0],
      claimLengths: claimLengths[0],
    });

    const outputs = await circuit.readWitnessSignals(witness, ["decodedClaims"]);

    const decodedClaims = outputs.decodedClaims as number[][];
    console.log("decodedClaims:", decodedClaims);
    // const circuitClaimHash = outputs.claimHashes as number[][];

    // for (let i = 0; i < inputs.length; i++) {
    //   const length = Number(claimLengths[i]);
    //   const base64 = decodedClaims[i]
    //     .slice(0, length)
    //     .map((c) => String.fromCharCode(Number(c)))
    //     .join("")
    //     .replace(/[\x00-\x1F]+$/g, "");

    //   assert.strictEqual(base64, expectedOutputs[i]);

    //   const expectedHash = sha256(Uint8Array.from(Buffer.from(inputs[i].slice(0, length), "utf8")));
    //   const expectedHashHex = Array.from(expectedHash, (b) => b.toString(16).padStart(2, "0")).join("");
    //   const circuitHashHex = circuitClaimHash[i].map((b) => b.toString(16).padStart(2, "0")).join("");

    //   assert.strictEqual(circuitHashHex, expectedHashHex);
    // }
    await circuit.expectConstraintPass(witness);
  });
});
