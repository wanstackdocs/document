// ftoc 输出两个华氏温度 - 摄氏温度转换
package main

import (
	"fmt"
)

func main() {
	const freezingF, boilingF = 32.0, 212.0
	fmt.Printf("%gF = %gC\n", freezingF, FToC(freezingF))
	fmt.Printf("%gF = %gC\n", boilingF, FToC(boilingF))
}

func FToC(f float64) float64 {
	return (f - 32) * 5 / 9
}
