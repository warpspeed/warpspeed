package main

import (
	"log"
	"net"
	"net/http"
	"os"
)

const SockAddr = "/home/vagrant/sites/go.sock"

func main() {

	http.HandleFunc("/", handler)

	os.Remove(SockAddr)
	unixListener, err := net.Listen("unix", SockAddr)
	if err != nil {
		log.Fatal("Listen (UNIX socket): ", err)
	}
	defer unixListener.Close()
	http.Serve(unixListener, nil)
}

func handler(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Warpspeed says hello, from GO!\n"))
}
