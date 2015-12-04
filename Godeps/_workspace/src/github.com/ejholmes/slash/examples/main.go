package main

import (
	"fmt"
	"net/http"
	"time"

	"github.com/ejholmes/slash"
	"golang.org/x/net/context"
)

func main() {
	h := slash.HandlerFunc(Handle)
	s := slash.NewServer(h)
	http.ListenAndServe(":8080", s)
}

func Handle(ctx context.Context, r slash.Responder, command slash.Command) (slash.Response, error) {
	go func() {
		for i := 0; i < 5; i++ {
			<-time.After(time.Second)
			err := r.Respond(slash.Reply(fmt.Sprintf("Async response %d", i)))
			if err != nil {
				fmt.Printf("error: %v\n", err)
			}
		}
	}()
	return slash.Reply("Cool beans"), nil
}
