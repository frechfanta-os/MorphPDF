package prompts

import "fmt"

// SystemPromptDocumentAssistant is the base system instruction for MorphPDF AI.
const SystemPromptDocumentAssistant = `Tu es l'assistant d'analyse documentaire intelligent de MorphPDF (développé par GHD Interactive Studio).
Tu es spécialisé dans l'analyse de documents, l'extraction précise d'informations, la correction textuelle et la synthèse.
Tes réponses doivent être rigoureuses, claires et fidèles au contenu fourni.`

// BuildAnalyzePrompt creates the prompt for structured document analysis.
func BuildAnalyzePrompt(documentText string, instructions string) (string, string) {
	system := SystemPromptDocumentAssistant + `
Tu dois retourner impérativement un objet JSON valide, sans texte additionnel, selon le schéma suivant :
{
  "summary": "résumé clair du document",
  "language": "code langue détecté (ex: fr, en, ar)",
  "document_type": "type de document (ex: Contrat, Facture, Devis, Rapport, Attestation)",
  "important_information": ["point important 1", "point important 2"],
  "dates": ["date 1", "date 2"],
  "amounts": ["montant 1", "montant 2"],
  "people": ["nom 1"],
  "organizations": ["organisation 1"],
  "issues": ["problème détecté ou ambiguïté"],
  "suggestions": ["suggestion d'amélioration ou action recommandée"]
}`

	user := fmt.Sprintf("Texte du document :\n\"\"\"\n%s\n\"\"\"\n", documentText)
	if instructions != "" {
		user += fmt.Sprintf("\nInstructions spécifiques de l'utilisateur : %s", instructions)
	}
	return system, user
}

// BuildCorrectPrompt creates the prompt for text correction.
func BuildCorrectPrompt(text string, context string) (string, string) {
	system := SystemPromptDocumentAssistant + `
Corrige les erreurs d'orthographe, de grammaire, de ponctuation et de syntaxe en conservant scrupuleusement le sens originel.
Renvoie uniquement le texte corrigé, sans introduction ni conclusion.`

	user := fmt.Sprintf("Texte à corriger :\n\"\"\"\n%s\n\"\"\"", text)
	if context != "" {
		user += fmt.Sprintf("\nContexte : %s", context)
	}
	return system, user
}

// BuildSummarizePrompt creates the prompt for document summarization.
func BuildSummarizePrompt(text string, maxLength int) (string, string) {
	system := SystemPromptDocumentAssistant + `
Produis un résumé concis, structuré et fidèle du document.`

	if maxLength <= 0 {
		maxLength = 500
	}
	user := fmt.Sprintf("Longueur maximale souhaitée : environ %d caractères.\nTexte du document :\n\"\"\"\n%s\n\"\"\"", maxLength, text)
	return system, user
}

// BuildExtractPrompt creates the prompt for extracting structured data or specific fields.
func BuildExtractPrompt(text string, schema string) (string, string) {
	system := SystemPromptDocumentAssistant + `
Extrais les données clés sous format JSON strict.`

	user := fmt.Sprintf("Schéma ou champs attendus : %s\nTexte du document :\n\"\"\"\n%s\n\"\"\"", schema, text)
	return system, user
}

// BuildTranslatePrompt creates the prompt for translating document text.
func BuildTranslatePrompt(text string, targetLanguage string) (string, string) {
	system := SystemPromptDocumentAssistant + fmt.Sprintf(`
Traduis le texte fidèlement vers la langue : %s.
Conserve la mise en forme et les termes techniques pertinents. Renvoie uniquement la traduction.`, targetLanguage)

	user := fmt.Sprintf("Texte à traduire :\n\"\"\"\n%s\n\"\"\"", text)
	return system, user
}

// BuildUserQuestionPrompt creates the prompt for Q&A on a document.
func BuildUserQuestionPrompt(documentText string, question string) (string, string) {
	system := SystemPromptDocumentAssistant + `
Réponds à la question de l'utilisateur en te basant uniquement sur le document fourni.`

	user := fmt.Sprintf("Document :\n\"\"\"\n%s\n\"\"\"\n\nQuestion de l'utilisateur : %s", documentText, question)
	return system, user
}
