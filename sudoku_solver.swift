//
//  SudokuSolver.swift
//  Sudoku
//
//  Created by 金田大生 on 2023/04/02.
//

// ref:https://www.youtube.com/@haskellhutt
import Foundation

typealias Grid = Matrix<Value>
typealias Matrix<A:Equatable> = [Row<A>]
typealias Row<A:Equatable> = [A]
typealias Value = Character
//Grid = Matrix<Value> = [Row Value] = [[Value]] = [[Character]] = [String]

let easy:Grid=[["8",".",".","1","3","5",".","7","."],
               [".","2",".",".","4",".","8","3","."],
               [".","6",".","7",".","8",".","4","."],
               [".",".",".","4","7",".","9",".","8"],
               ["2","4",".",".","8",".",".",".","."],
               [".","3","8",".",".",".",".",".","5"],
               [".","8",".","6",".","4","1",".","."],
               ["9",".",".",".",".","7","2",".","4"],
               [".",".","5","8","1",".",".",".","6"]]

let crazy:Grid=[["8",".",".",".",".",".",".",".","."],
                [".",".","3","6",".",".",".",".","."],
                [".","7",".",".","9",".","2",".","."],
                [".","5",".",".",".","7",".",".","."],
                [".",".",".",".","4","5","7",".","."],
                [".",".",".","1",".",".",".","3","."],
                [".",".","1",".",".",".",".","6","8"],
                [".",".","8","5",".",".",".","1","."],
                [".","9",".",".",".",".","4",".","."]]

let blank:Grid = Array(repeating: Array(repeating: ".", count: 9), count: 9)

//あとで行ごとに数字の重複がないかを確かめる述語を作るので、行を行、列を行、各小行列を行とする関数を作る。(他のルールも同様に作れるかもしれない)


func rows<A:Equatable>(_ m:Matrix<A>)->Matrix<A>{
    return m
}

//転置
func cols<A:Equatable>()->(Matrix<A>)->Matrix<A>{
    return transpose(_:)
}

func transpose<A:Equatable>(_ m:Matrix<A>)->Matrix<A>{
    var result:Matrix<A> = Array(repeating: [], count: m.count)
    for i in 0..<m.count{
        for j in 0..<m.count{
            result[j].append(m[i][j])
        }
    }
    return result
}
//
//let sample:Grid = [
//    ["a","b","c","d"],
//    ["e","f","g","h"],
//    ["i","j","k","l"],
//    ["m","n","o","p"]
//]
//ボックスを行にする操作
let boxSize:Int = 3

func boxs<A:Equatable>(_ m:Matrix<A>)->Matrix<A>{
    return concat(chop(boxSize,m.map{chop(boxSize,$0)})
        .map{cols()($0)})
        .map {concat($0)}
}

func chop<A>(_ n:Int,_ xs:Array<A>)->Array<Array<A>>{
    var result :Array<Array<A>> = Array(repeating: [], count: n)
    for i in 0..<boxSize{
        result[i] = Array(xs[n*i..<n*(i+1)])
    }
    return result
}

func concat<A>(_ list:Array<Array<A>>)->Array<A>{
    var result:Array<A> = []
    for i in 0..<list.count{
        result += list[i]
    }
    return result
}

//重要な性質
//rows . rows = id
//cols . cols = id
//boxs . boxs = id ただし.は合成関数を意味し、idは恒等関数,boxsについては転置と強く関連あり

//１行の正当性をチェックする　validを定義する。すなわち、一行の数字に重複がないことを確かめるvalidを定義する.上の列を行、ボックスを行にする考えから、行のチェックで十分である。
func valid(_ g:Grid)->Bool{
    func all(_ bs:[Bool])->Bool{
       return !bs.contains(false)
    }
    
    return all((rows(g)).map{nodups($0)}) && all((cols()(g)).map{nodups($0)}) && all((boxs(g)).map{nodups($0)})
}
//２個以上含む同じ要素の判定による
func nodups<A:Equatable>(_ r:Row<A>)->Bool{
    return r.filter { x in
        r.filter { y in
            x==y
        }.count>=2
    }.count==0
}

//解を求める関数solve 総当たりほうでまずは効率を考えない。
typealias Choices = [Value]

 func solve(_ g:Grid)->[Grid]{
 return collapse(choices(g)).filter{valid($0)}
 }
// choicesは空欄（".")のところに["1","2",..."9"]を入れ、数字には[]をつけて返すというMatrix Choicesを返すもの
// collapse　はリストのリストを受け取って、その直積を返す関数を2回適応したもの


func choices(_ m:Matrix<Value>)->Matrix<Choices>{
    func choice(_ c:Value)->Choices{
        if(c=="."){
            return ["1","2","3","4","5","6","7","8","9"]
        }else{
            return [c]
        }
    }
    return m.map{r in
        r.map{
            choice($0)
        }
    }
}

//collapseを定義する前にリスト[A_1,A_2,A_3,...A_n]に対してA_1×A_2×A_3...×A_nという直積を求める関数を定める
//まず、二つのリストの直積を求めるところから始めよう
func cp2<A:Equatable>(_ l1:[A],_ l2:[A])->[[A]]{
    var result:[[A]]=Array(repeating: [], count: l1.count*l2.count)
    for i in 0..<l1.count{
        for j in 0..<l2.count{
            result[l2.count*i+j] = [l1[i],l2[j]]
        }
    }
    return result
}
//cp3は再帰的にA×(B×C)を考えるときに用いる。 cp2を繰り返し適応するとカッコが増えすぎてしまう問題を解消
func cp3<A:Equatable>(_ l1:[A],_ l2:[[A]])->[[A]]{
    var result:[[A]]=Array(repeating: [], count: l1.count*l2.count)
    for i in 0..<l1.count{
        for j in 0..<l2.count{
            result[l2.count*i+j] = [l1[i]]+l2[j]
        }
    }
    return result
}
func cp<A:Equatable>(_ list:[[A]])->[[A]]{
   // var result:[[A]] = []
    func smallCp<A:Equatable>(_ list:[[A]])->[[A]]{
        if(list.count<2){
            return list
        }else if(list.count == 2){
            return cp2(list[0], list[1])
        }else{
            let recursiveList:[[A]] = Array(list.dropFirst())
            return cp3(list[0], smallCp(recursiveList))
        }
    }
    return smallCp(list)
}

func collapse(_ m:Matrix<Choices>)->[Matrix<Value>]{
    return cp(m.map{cp($0)})
}


//今のままでは計算量が大きすぎるので、計算量を減らす工夫をする

//idea1:choicesの選択肢を減らす関数pruneの定義

//まず、初期値(初めからますに入っている値)をChoiceから取り除く関数reduceを定義する
func reduce<A:Equatable>(_ r:Row<[A]>)->Row<[A]>{
    let def:[A] = r.filter { choices in
        choices.count == 1
    }.flatMap {$0}
    
    return r.map { choice in
        miniReduce(def, choice)
    }
}

func miniReduce<A:Equatable>(_ def:[A],_ choice:[A])->[A]{
    if(choice.count<=1){
        return choice
    }else{
        return choice.filter{c in
            !def.contains(c)
        }
    }
}

//関数合成演算子の定義（記述の簡潔化のため)

infix operator • : CompositionPrecedence

precedencegroup CompositionPrecedence {
    associativity: left
    higherThan: TernaryPrecedence
}

func •<T, U, V>(g: @escaping (U) -> V, f: @escaping (T) -> U) -> ((T) -> V) {
    return { g(f($0)) }
}

func prune<A:Equatable>(_ m:Matrix<[A]>)->Matrix<[A]>{
    return pruneBy(rows(_:), pruneBy(cols(), pruneBy(boxs(_:), m)))
    //行がボックスを表すように変形ー＞ボックスの重複を取り除く->元に戻す->列がボックスを表すように変形...
    
    func pruneBy<A:Equatable>(_ f:(Matrix<[A]>) -> Matrix<[A]>, _ m:Matrix<[A]>) -> Matrix<[A]>{
        return f(f(m).map{reduce($0)})
    }
}

func solve2(_ g:Grid)->[Grid]{
    return collapse(prune(choices(g))).filter {valid($0)}
}


//改善案２、pruneを一回適応することで、一つだけの数字が定まるますができることがあるので、それを再び初期値として加えて、pruneを再度適応することには意味がある。pruneを複数回適応することで選択肢を減らすことを考える

//fix :: Eq a => (a -> a) -> a -> a
//fix f x = if x == x' then x' else f x'
//          where x' = f x

func fix<A:Equatable>(_ f:(A)->A,_ a:A)->A{
    if(a==f(a)){
        return f(a)
    }else{
        return fix(f, f(a))
    }
}

func solve3(_ g:Grid)->[Grid]{
    return collapse(fix(prune(_:),choices(g))).filter {valid($0)}
}


//collapseをより精密にして、計算量を減らすことを目標にする。例えば、単一の要素を含まない最初のChoiceを1マスごとに分解していき、その度に無効なものを間引くようにする

//無効なMatrix Choice、すなわち、collapseしても正解が含まれないMatrix Choiceを検出することを考える.
//正解を導かないMatrix Choice の必要条件はChoiceに空リストを含むか重複する単一Choiceがいずれかの行、列ボックスにあることである。逆に、そのどちらも成り立たず、かくChoiceが単一の選択肢のみを持つならば、明らかにそれをcollapseすれば、一つの解となる

//空のChoiceを含むかどうかを確かめる関数blank
func blank(_ m:Matrix<Choices>)->Bool{
    m.flatMap{$0}.contains([])
}

//Choiceの行列を受け取って、各行、各列、各ボックス、単一の重複するChoiceが存在しないかどうかを確かめる関数safe
func safe(_ m:Matrix<Choices>)->Bool{
    return rows(m).allSatisfy {consistent($0)} && cols()(m).allSatisfy {consistent($0)} && boxs(m).allSatisfy {consistent($0)}
}
  //一つのRow<Choice>に重複する単一のChoiceが存在しないかどうかを確かめるconsistent
func consistent<A:Equatable>(_ r:Row<[A]>)->Bool{
    return nodups(r.filter{$0.count==1})
}

//Choicesの行列を受け取って、それが明らかに正解を導かない場合にTrueを返すblocked
func blocked(_ m:Matrix<Choices>)->Bool{
    return blank(m) || !(safe(m))
}

//Choicesの行列を受け取って、初めての単一でないChoicesを検出して、そのマスだけを分解した[Matrix<Choices>]の値を返す関数expand(collapseを使わずに一ますずつ分解していくために必要)
func expand(_ m:Matrix<Choices>)->[Matrix<Choices>]{
    
    let rows1:[Row<Choices>] = Array(m.prefix {$0.allSatisfy { choices in
        choices.count == 1
    }})
    let rows2:[Row<Choices>] = Array(m.drop(while: { row in
        row.allSatisfy { choices in
            choices.count == 1
        }
    }))
    //単一の選択肢以外を含む初めてのRow<Choice>
    let row:Row<Choices> = rows2.first ?? []
    
    let row1:Row<Choices> = Array(row.prefix { choices in
        choices.count == 1
    })
    let row2:Row<Choices> = Array(row.drop{ choices in
        choices.count == 1
    })
    let cs:Choices? = row2.first ?? nil
    var collapsed:[Matrix<Choices>] = []
    if let choices=cs{
        for c in choices{
            let newRow:Row<Choices> = row1 + [[c]] + Array(row2.dropFirst())
            collapsed.append(rows1 + [newRow] + Array(rows2.dropFirst()))
        }
        return collapsed
    }else{
        return [m]
    }
}
/*
 in haskell
 expand m              =
 [rows1 ++ [row1 ++ [c] : row2] ++ rows2 | c <- cs]
 where
   (rows1,row:rows2) = break (any (not . single)) m
   (row1,cs:row2)    = break (not . single) row
*/

func search(_ m:Matrix<Choices>)->[Grid]{
   
        if(blocked(m)){
            return []
        }else if(m.allSatisfy({row in
            row.allSatisfy { choices in
                choices.count == 1
            }
        })){
            return collapse(m)
        }else{
            return expand(m).map{search(prune($0))}.flatMap{$0}
        }
    }
    

/*
 in haskell
 search ::Matrix Choices -> [Grid]
 search m
  | blocked m = []
  | all (all single) m = collapse m
  | otherwise = [g|m'<- expand m,g<- search (prune m')]
 */

func solve4(_ m:Grid)->[Grid]{
    return (search • prune • choices)(m)
}
