package main

import (
	"fmt"
	"os"
)

func main() {
	// fmt.Println(os.Args[0])
	for index, args := range os.Args[1:] {
		fmt.Println(index, args)
	}
}
