pragma circom 2.1.6;

include "es256.circom";
include "jwt_tx_builder/header-payload-extractor.circom";
include "jwt_tx_builder/array.circom";
include "keyless_zk_proofs/arrays.circom";
include "@zk-email/circuits/lib/sha.circom";
include "claim-decoder.circom";
include "age-verifier.circom";
include "utils.circom";

template JWT(
    n,
    k,

    maxMessageLength,
    maxB64HeaderLength,
    maxB64PayloadLength,

    maxMatches,
    maxSubstringLength,
    maxClaimsLength
) {
    var decodedLen = (maxClaimsLength * 3) / 4;

    signal input message[maxMessageLength]; // JWT message (header + payload)
    signal input messageLength; // Length of the message signed in the JWT
    signal input periodIndex; // Index of the period in the JWT message

    signal input sig_r[k];
    signal input sig_s[k];
    signal input pubkey[2][k];

    signal input matchesCount;
    signal input matchSubstring[maxMatches][maxSubstringLength];
    signal input matchLength[maxMatches];
    signal input matchIndex[maxMatches];

    signal input claims[maxMatches][maxClaimsLength];
    signal input claimLengths[maxMatches];
    
    signal input currentYear;
    signal input currentMonth;
    signal input currentDay;

    signal input ageClaim[maxClaimsLength];
    signal input ageClaimLength;

    // component claimDecoder = ClaimDecoder(maxMatches, maxClaimsLength);
    // claimDecoder.claims <== claims;
    // claimDecoder.claimLengths <== claimLengths;
        
    // ClaimComparator(maxMatches, maxSubstringLength)(claimDecoder.claimHashes ,claimLengths, matchSubstring, matchLength);

    // component es256 = ES256(n,k,maxMessageLength);
    // es256.message <== message;
    // es256.messageLength <== messageLength;
    // es256.sig_r <== sig_r;
    // es256.sig_s <== sig_s;
    // es256.pubkey <== pubkey;

    // *
    component ageDecoder = AgeClaimDecoder(maxClaimsLength);
    ageDecoder.claims <== ageClaim;
    ageDecoder.claimLengths <== ageClaimLength;
    // *

    component extractor = HeaderPayloadExtractor(maxMessageLength,maxB64HeaderLength, maxB64PayloadLength);
    extractor.message <== message;
    extractor.messageLength <== messageLength;
    extractor.periodIndex <== periodIndex;    

    component enableMacher[maxMatches];
    component matcher[maxMatches];
    var       maxPayloadLength = (maxB64PayloadLength * 3) \ 4;

    for (var i=0;i<maxMatches;i++) {
        enableMacher[i] = LessThan(8);
        enableMacher[i].in[0] <== i;
        enableMacher[i].in[1] <== matchesCount;

        matcher[i] = CheckSubstrInclusionPoly(maxPayloadLength,maxSubstringLength);
        matcher[i].str <== extractor.payload;
        matcher[i].str_hash <== 81283812381238128;
        matcher[i].substr <== matchSubstring[i];
        matcher[i].substr_len <== matchLength[i];
        matcher[i].start_index <== matchIndex[i];
        matcher[i].enabled <== enableMacher[i].out;
    }

    // signal output ageAbove18 <== AgeVerifier(decodedLen)(claimDecoder.decodedClaims[1], currentYear, currentMonth, currentDay);
    signal output ageAbove18 <== AgeVerifier(decodedLen)(ageDecoder.decodedClaims, currentYear, currentMonth, currentDay);
}