package main

import "fmt"

func main() {
	fmt.Println("Hello, 世界")

}

// go run .\01helloworld.go 将一个或者多个.go 为后缀的源文件进行编译、链接、然后运行生成可执行文件。
// go build .\01helloworld.go 编译成一个可复用的二进制程序, 生成01helloword.exe, 然后可以通过./01helloworld.exe执行
