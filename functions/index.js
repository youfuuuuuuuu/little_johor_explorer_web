const { onRequest } = require("firebase-functions/v2/https");
const { GoogleGenAI } = require("@google/genai");

exports.chatWithGemini = onRequest(
  {
    // Binds the secret you just created to the environment variable
    secrets: ["GEMINI_API_KEY"],
    cors: true, // Enables CORS so Flutter web/apps can hit this endpoint
  },
  async (req, res) => {
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Only POST requests are allowed." });
    }

    try {
      const { contents, systemInstruction } = req.body;

      if (!contents) {
        return res.status(400).json({ error: "Missing 'contents' in request body." });
      }

      // Initialize Google Gen AI with the secret key
      const ai = new GoogleGenAI({
        apiKey: process.env.GEMINI_API_KEY,
      });

      // Request content generation from gemini-3.1-flash-lite
      const response = await ai.models.generateContent({
        model: "gemini-3.1-flash-lite",
        contents: contents,
        config: systemInstruction
          ? { systemInstruction: systemInstruction }
          : undefined,
      });

      return res.status(200).json(response);
    } catch (error) {
      console.error("Gemini Cloud Function Error:", error);
      return res.status(500).json({
        error: error.message || "An error occurred calling Gemini API.",
      });
    }
  }
);