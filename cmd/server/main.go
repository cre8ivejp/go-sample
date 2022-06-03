package main

import (
	"context"
	"log"
	"net"
	"time"

	"google.golang.org/grpc"

	pingproto "github.com/cre8ivejp/go-sample/proto/ping"
)

const (
	port = ":8080"
)

type server struct{}

func (s *server) Ping(ctx context.Context, in *pingproto.PingRequest) (*pingproto.PingResponse, error) {
	return &pingproto.PingResponse{Timestamp: time.Now().Unix()}, nil
}

func main() {
	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatal(err)
	}

	s := grpc.NewServer()
	pingproto.RegisterPingServer(s, &server{})
	if err := s.Serve(lis); err != nil {
		log.Fatal(err)
	}
}
