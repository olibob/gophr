package main

import (
	"fmt"
	"html/template"
	"net/http"
)

var templates = template.Must(template.New("t").ParseGlob("templates/**/*.html"))

// RenderTemplate renders a named template for a specific interface
func RenderTemplate(w http.ResponseWriter, r *http.Request, name string, data interface{}) {
	err := templates.ExecuteTemplate(w, name, data)
	if err != nil {
		http.Error(
			w,
			fmt.Sprintf(errorTemplate, name, err),
			http.StatusInternalServerError,
		)
	}
}

var errorTemplate = `
<html>
  <body>
    <h1>Error rendering template %s</h1>
    <p>%s</p>
  </body>
</html>`
