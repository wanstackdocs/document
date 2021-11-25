// fetchall 并发获取 URL 并报告他们的时间和大小
package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"time"
)

func main() {
	start := time.Now()
	ch := make(chan string)
	for _, url := range os.Args[1:] {
		go fetch(url, ch) // 启动一个 goroutine
	}
	for range os.Args[1:] {
		fmt.Println(<-ch) // 从通道中接收
	}
	fmt.Printf("%.2f elapsed\n", time.Since(start).Seconds())
}

func fetch(url string, ch chan<- string) {
	start := time.Now()
	resp, err := http.Get(url)
	if err != nil {
		ch <- fmt.Sprint(err) // 发送到通道ch ，用传入的格式化规则符将传入的变量格式化，(终端中不会有显示)
		return
	}
	// COPY读取响应的内容，然后通过写入Dicard输出流进行丢弃，仅返回字节数
	nbytes, err := io.Copy(ioutil.Discard, resp.Body)
	resp.Body.Close()
	if err != nil {
		ch <- fmt.Sprintf("while reading %s: %v", url, err)
		return
	}
	secs := time.Since(start).Seconds() // 时间差
	// %2.f 表示最大保留2位小数，%7d 表示最大保留7位十进制数
	ch <- fmt.Sprintf("%.2fs	%7d		%s", secs, nbytes, url)
}
