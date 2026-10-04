package models

import "time"

// Document represents a processed or imported document metadata.
type Document struct {
	ID        string    `json:"id"`
	FileName  string    `json:"fileName"`
	MimeType  string    `json:"mimeType"`
	FileSize  int64     `json:"fileSize"`
	PageCount int       `json:"pageCount"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
	Status    string    `json:"status"` // e.g. "pending", "processing", "ready", "error"
}

// Page represents page dimensions and rotation.
type Page struct {
	PageNumber int     `json:"pageNumber"`
	Width      float64 `json:"width"`
	Height     float64 `json:"height"`
	Rotation   int     `json:"rotation"`
}

// TextBlock represents an extracted or detected block of text with coordinates.
type TextBlock struct {
	ID         string  `json:"id"`
	PageNumber int     `json:"pageNumber"`
	Text       string  `json:"text"`
	X          float64 `json:"x"`
	Y          float64 `json:"y"`
	Width      float64 `json:"width"`
	Height     float64 `json:"height"`
	Confidence float64 `json:"confidence"`
	Language   string  `json:"language"`
}

// ImageBlock represents an image extracted or detected within a document page.
type ImageBlock struct {
	ID         string  `json:"id"`
	PageNumber int     `json:"pageNumber"`
	X          float64 `json:"x"`
	Y          float64 `json:"y"`
	Width      float64 `json:"width"`
	Height     float64 `json:"height"`
	Source     string  `json:"source"`
}

// TableBlock represents a table element detected within a document page.
type TableBlock struct {
	ID         string  `json:"id"`
	PageNumber int     `json:"pageNumber"`
	X          float64 `json:"x"`
	Y          float64 `json:"y"`
	Width      float64 `json:"width"`
	Height     float64 `json:"height"`
	Rows       int     `json:"rows"`
	Columns    int     `json:"columns"`
}
