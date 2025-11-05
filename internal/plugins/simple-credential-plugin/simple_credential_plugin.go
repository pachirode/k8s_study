package main

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
)

type Credential struct {
	Token string `json:"token"`
}

func main() {
	token := "your-static-token"

	credential := Credential{Token: token}

	resp, err := json.Marshal(credential)
	if err != nil {
		slog.Error("Error marshaling response", "err", err)
		os.Exit(1)
	}

	fmt.Println(string(resp))
}
