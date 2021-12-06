字符串中的每一个元素叫做“字符”，在遍历或者单个获取字符串元素时可以获得字符。

Go语言的字符有以下两种：
一种是 uint8 类型，或者叫 byte 型，代表了 ASCII 码的一个字符。
另一种是 rune 类型，代表一个 UTF-8 字符，当需要处理中文、日文或者其他复合字符时，则需要用到 rune 类型。rune 类型等价于 int32 类型。

byte 类型是 uint8 的别名，对于只占用 1 个字节的传统 ASCII 编码的字符来说，完全没有问题，例如 var ch byte = 'A'，字符使用单引号括起来。

在 ASCII 码表中，A 的值是 65，使用 16 进制表示则为 41，所以下面的写法是等效的：
var ch byte = 65 或 var ch byte = '\x41'      //（\x 总是紧跟着长度为 2 的 16 进制数）

另外一种可能的写法是\后面紧跟着长度为 3 的八进制数，例如 \377。

Go语言同样支持 Unicode（UTF-8），因此字符同样称为 Unicode 代码点或者 runes，并在内存中使用 int 来表示。在文档中，一般使用格式 U+hhhh 来表示，其中 h 表示一个 16 进制数。

在书写 Unicode 字符时，需要在 16 进制数之前加上前缀\u或者\U。因为 Unicode 至少占用 2 个字节，所以我们使用 int16 或者 int 类型来表示。如果需要使用到 4 字节，则使用\u前缀，如果需要使用到 8 个字节，则使用\U前缀。
var ch int = '\u0041'
var ch2 int = '\u03B2'
var ch3 int = '\U00101234'
fmt.Printf("%d - %d - %d\n", ch, ch2, ch3) // integer
fmt.Printf("%c - %c - %c\n", ch, ch2, ch3) // character
fmt.Printf("%X - %X - %X\n", ch, ch2, ch3) // UTF-8 bytes
fmt.Printf("%U - %U - %U", ch, ch2, ch3)   // UTF-8 code point
输出：
65 - 946 - 1053236
A - β - r
41 - 3B2 - 101234
U+0041 - U+03B2 - U+101234

格式化说明符%c用于表示字符，当和字符配合使用时，%v或%d会输出用于表示该字符的整数，%U输出格式为 U+hhhh 的字符串。

Unicode 包中内置了一些用于测试字符的函数，这些函数的返回值都是一个布尔值，如下所示（其中 ch 代表字符）：
判断是否为字母：unicode.IsLetter(ch)
判断是否为数字：unicode.IsDigit(ch)
判断是否为空白符号：unicode.IsSpace(ch)
UTF-8 和 Unicode 有何区别？
Unicode 与 ASCII 类似，都是一种字符集。

字符集为每个字符分配一个唯一的 ID，我们使用到的所有字符在 Unicode 字符集中都有一个唯一的 ID，例如上面例子中的 a 在 Unicode 与 ASCII 中的编码都是 97。汉字“你”在 Unicode 中的编码为 20320，在不同国家的字符集中，字符所对应的 ID 也会不同。而无论任何情况下，Unicode 中的字符的 ID 都是不会变化的。

UTF-8 是编码规则，将 Unicode 中字符的 ID 以某种方式进行编码，UTF-8 的是一种变长编码规则，从 1 到 4 个字节不等。编码规则如下：
0xxxxxx 表示文字符号 0～127，兼容 ASCII 字符集。
从 128 到 0x10ffff 表示其他字符。

根据这个规则，拉丁文语系的字符编码一般情况下每个字符占用一个字节，而中文每个字符占用 3 个字节。

广义的 Unicode 指的是一个标准，它定义了字符集及编码规则，即 Unicode 字符集和 UTF-8、UTF-16 编码等。




golang内置类型有rune类型和byte类型。

rune类型的底层类型是int32类型，而byte类型的底层类型是int8类型，这决定了rune能比byte表达更多的数。

在unicode中，一个中文占两个字节，utf-8中一个中文占三个字节，golang默认的编码是utf-8编码，因此默认一个中文占三个字节，但是golang中的字符串底层实际上是一个byte数组。因此可能会出现下面这种奇怪的情况
```go
package main
 
import (
    "fmt"
)
 
func main() {
    str := "世界"
    fmt.Println(len(str)) //6
}
```

我们期望得到的结果应该是4，原因是golang中的string底层是由一个byte数组实现的，而golang默认的编码是utf-8，因此在这里一个中文字符占3个字节，所以获得的长度是6，想要获得我们想要的结果也很简单，golang中的unicode/utf8包提供了用utf-8获取长度的方法
```go
package main
 
import (
    "fmt"
    "unicode/utf8"
)
 
func main() {
    str := "世界"
    fmt.Println(utf8.RuneCountInString(str))//2
 
}
```
结果是2


上面说了byte类型实际上是一个int8类型，int8适合表达ascii编码的字符，而int32可以表达更多的数，可以更容易的处理unicode字符，因此，我们可以通过rune类型来处理unicode字符
```go
package main
 
import (
    "fmt"
)
 
func main() {
    str := "hello 世界"
    str2 := []rune(str)
    fmt.Println(len(str2)) //8
 
}
```
这里将会申请一块内存，然后将str的内容复制到这块内存，实际上这块内存是一个rune类型的切片，而str2拿到的是一个rune类型的切片的引用，我们可以很容易的证明这是一个引用
```go
package main
import (
    "fmt"
)
func main() {
    str := "hello 世界"
    str2 := []rune(str)
    t := str2
    t[0] = 'w'
    fmt.Println(string(str2)) //“wello 世界”
    fmt.Println(string(str))  //“hello 世界”
}
```

通过把str2赋值给t，t上改变的数据，实际上是改变的是t指向的rune切片，因此，str2也会跟着改变，而str不会改变。

字符串的遍历
对于字符串，看一下如何遍历吧，也许你会觉得遍历轻而易举，然而刚接触golang的时候，如果这样遍历字符串，那么将是非常糟糕的
```go
package main
 
import (
    "fmt"
)
 
func main() {
    str := "hello 世界"
 
    for i := 0; i < len(str); i++ {
        fmt.Println(string(str[i]))
    }
 
}
```

输出:

h
e
l
l
o
  
ä
¸

ç
　　

如何解决这个问题呢？

第一个解决方法是用range循环
```go
package main
 
import (
    "fmt"
)
 
func main() {
    str := "hello 世界"
 
    for _, v := range str {
        fmt.Println(string(v))
    }
}
```
　输出

h
e
l
l
o
  
世
界
　原因是range会隐式的unicode解码

第二个方法是将str 转换为rune类型的切片
```go
package main
 
import (
    "fmt"
)
 
func main() {
    str := "hello 世界"
    str2 := []rune(str)
 
    for i := 0; i < len(str2); i++ {
        fmt.Println(string(str2[i]))
    }
 
}
```　

　输出
h
e
l
l
o
  
世
界
　

rune和byte的区别
除开rune和byte底层的类型的区别，在使用上，rune能处理一切的字符，而byte仅仅局限在ascii