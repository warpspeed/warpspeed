package main

import (
	"os"
	"fmt"
	"net/http"
	"log"
	"net"
)

const (
	sockAddr = "./app.sock"
)

func main() {

	os.Remove(sockAddr)
	unixListener, err := net.Listen("unix", sockAddr)
	if err != nil {
		log.Fatal("Listen (UNIX socket): ", err)
	}
	defer unixListener.Close()

	http.HandleFunc("/", HelloServer)
	http.Serve(unixListener, nil)

}

func HelloServer(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello, %s!", r.URL.Path[1:])
}
