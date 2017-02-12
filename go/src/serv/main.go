package main

import (
    "io"
    "log"
    "net/http"
)

func HandleIndex(w http.ResponseWriter, r *http.Request) {
    io.WriteString(w, "Hello, world!")
}

func main() {
    http.HandleFunc("/", HandleIndex)
    log.Fatal(http.ListenAndServe(":8005", nil))
}
