package main

import (
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
)

func main() {
	port := flag.Int("port", 80, "")
	flag.Parse()

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, World!\n")
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "OK\n")
	})

	http.HandleFunc("/guardduty/trigger", func(w http.ResponseWriter, r *http.Request) {
		resp, err := http.Get("https://google-gruyere.appspot.com")
		if err != nil {
			log.Println(err)
			fmt.Fprintln(w, err.Error())
			return
		}
		_, err = io.ReadAll(resp.Body)
		if err != nil {
			log.Println(err)
			fmt.Fprintln(w, err.Error())
			return
		}
		fmt.Fprintf(w, "OK\n")
	})

	addr := fmt.Sprintf(":%d", *port)
	err := http.ListenAndServe(addr, nil)
	if err != nil {
		fmt.Println("Error starting the server: ", err)
	}
}
