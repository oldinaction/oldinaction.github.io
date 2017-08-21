---
layout: "post"
title: "Excel VBA"
date: "2017-06-25 14:03"
categories: [others]
tags: [excel, vb]
---

## 简介

- `VBA`：Visual Basic for Applications是Visual Basic的一种宏语言
- [官方VBA文档](https://msdn.microsoft.com/zh-cn/library/ee861528.aspx)、[官方Excel帮助](https://support.office.com/zh-cn/excel)、[官方VB文档](https://docs.microsoft.com/zh-cn/dotnet/visual-basic/index)
- [基础语法](http://www.yiibai.com/vba/vba_for_loop.html)、[51自学视频(后面几章收费)](http://www.51zxw.net/list.aspx?cid=539)

## 语法

- 不会写法的可以使用录制宏，然后进行代码查看

- `FormulaR1C1`是公式输入方法
    - 有中括号是相对于选定单元格的相对偏移量，"-"为向左或向上偏移，正数为右或下偏移。 无中括号为相对于选定单元格的绝对偏移量，没有负数。"R"和"C"对应行和列”
    - 如：C1单元格为"=A1+B1"。Range("C1").FormulaR1C1 = "=RC[-2]+RC[-1]"
    - 如：C1单元格为"=A2+E3" Range("C1").FormulaR1C1 = "=R[1]C[-2]+R[2]C[2]"
- `Selection.AutoFill Destination:=fillRange, Type:=xlFillDefault` 自动填充
    - 此处`Selection`选中的Range即sourceRange(源)，根据sourceRange进行fillRange的填充。此时fillRange必须包含sourceRange。sourceRange中可以有公式等
- `ActiveWindow.SmallScroll Down:=6`等是对窗口进行移动，不影响计算

## 宏界面配置

- 设置字体：工具-选项-编辑器格式-标准字体-Consolas (西方)
- 设置语法检测：工具-选项-编辑器-自动语法检测去勾选。防止编辑时弹框提示语法错误，运行时语法错误会提示

## 示例

### Delat Ct法计算候选基因稳定性

> 此算法是临时帮朋友写的，可能与实际算法不符，仅供参考

- 简介：这是一种常见的算法，叫做Delat Ct法计算候选基因稳定性。最后得到的是每个基因的mean SD值，首先计算两个基因的ΔCt值，再计算其ΔCt值的方差，最后得到该基因与其余每个基因ΔCt值的方差的平均值。
- excel表格数据如下：


  |beta-Actin   |Tubulin-alpha   |EF1A   |GAPDH   |Tubulin-beta   |18S rRNA  
--|---|---|---|---|---|--
卵子  |23.82   |23.82   |23.93   |25.48   | 25.76  | 17.67
受精后  |22.47  |23.94  |22.51   | 23.31  | 23.91  |13.74  
2cell	|23.29  |24.78  |22.83	|24.23  |25.05  |15.35
4cell   |22.95	|24.84	|22.51	|23.39	|24.54	|14.6
8cell	|21.75	|23.77	|21.8	|22.58	|23.66	|13.22
16cell	|21.82	|24.21	|22.49	|23.45	|23.8	|12.73
32cell	|21.92	|24.62	|22.33	|23.74	|21.12	|13.95
64cell	|22.92	|24.83	|22.19	|24.39	|24.9	|15.76
多cell	|21.62	|24.04	|21.26	|22.66	|24.04	|12.63
高囊胚1	|23.06	|25.08	|23.08	|24.45	|25.09	|15.17
高囊胚2	|22.98	|26.27	|22.22	|25.04	|25.72	|15.55
低囊胚	|23	|26.24	|22.03	|26.31	|26.49	|17.04
原肠胚前期	|21.23	|25.46	|20	|26.46	|25.87	|14.12
原肠胚中期	|20.23	|24.6	|19.52	|26.57	|25.81	|14.03
原肠胚后期	|19.56	|22.77	|18.5	|26.3	|24.91	|12.83
神经	|19.46	|23.87	|17.66	|26.82	|24.58	|15.86
肌节	|18.03	|22.7	|16.48	|23.35	|23.79	|12.86
器官形成期1	|18.47	|23.71	|17.26	|24.89	|24.21	|15.3
器官形成期2	|18.65	|23.6	|17.83	|23.94	|23.74	|15.92
器官形成期3	|18.14	|23.24	|16.12	|23.66	|23.82	|16
破膜	|17.82	|22.89	|17.45	|5.44	|23.92	|13.92
仔鱼	|16.97	|22.65	|16.15	|20.69	|22.86	|11.55

- ![大概效果](data/images/2017/08/delacCt.png)

- VBA处理源码(效率可能较低)

    ```visual-basic

    Sub delacCt()
    '
    ' Delac Ct算法计算基因mean SD 宏
    '
        Dim rows As Integer
        Dim columns As Integer
        Dim rangeItem1 As range
        Dim rangeItem2 As range
        Dim targetCellRange1 As range
        Dim targetCellRange2 As range
        Dim isStart As Boolean

        'dataCell为一个Range对象
        Set myRange = Application.InputBox(prompt:="按住Shift选择数据所在区域（包含行标题不包含列标题）", Type:=8)
        'Set myRange = range("B1:D23")

        '获取此区域的总行数和总列数
        rows = myRange.rows.count
        columns = myRange.columns.count

        '循环其中两个基因
        With myRange
            For i = 1 To columns Step 1
                '每一行的方差
                Dim total As Double
                total = 0

                For j = i + 1 To columns Step 1
                    '此处.代表myRange(With中)
                    Set rangeItem1 = .columns(i)
                    Set rangeItem2 = .columns(j)

                    Dim cellRow As Integer
                    Dim cellColumn As Integer
                    cellRow = i * (rows + 3) + 1
                    cellColumn = (j - 2) * 4 + 2

                    '目标单元格
                    Set targetCellRange1 = Worksheets(1).Cells(cellRow, cellColumn)
                    Set targetCellRange2 = Worksheets(1).Cells(cellRow, cellColumn + 1)

                    '复制并粘贴其中某两个基因
                    Call geneCopy(rangeItem1, targetCellRange1)
                    Call geneCopy(rangeItem2, targetCellRange2)

                    '计算方差
                    total = total + geneCalculate(range(targetCellRange1, targetCellRange1.Offset(rows - 1, 0)))
                Next

                ' 计算方差平均值
                If i < columns Then
                    'MsgBox total / (columns - i)
                    Dim row As Integer
                    '方差所在行
                    row = targetCellRange1.Offset(rows - 1, 0).row + 1

                    Worksheets(1).range("A" & row).Value = "SD"
                    Worksheets(1).range("A" & row + 1).Value = "mean SD"
                    Worksheets(1).range("B" & row + 1).Value = total / (columns - i)
                End If
            Next
        End With

        'ActiveWorkbook.Save
    End Sub

    Private Sub geneCopy(rangeItem As range, targetCellRange As range)
    '
    ' 复制并粘贴其中某两个基因
    '
        rangeItem.Select
        Selection.Copy

        targetCellRange.Select
        ActiveSheet.Paste
    End Sub

    Private Function geneCalculate(targetRange1 As range) As Double
    '
    ' 对两个基因进行计算
    '
        '求差值
        Call subValue(targetRange1)

        '求方差(targetRange1.Row是获取该单元格得在Sheet中是第几行)
        geneCalculate = varianceValue(range(Worksheets(1).Cells(targetRange1.row + 1, targetRange1.Column + 2), _
                Worksheets(1).Cells(targetRange1.row + targetRange1.rows.count - 1, targetRange1.Column + 2)))

        'MsgBox geneCalculate
    End Function

    Private Sub subValue(rangeItem1 As range)
    '
    ' 求差值
    '
        Dim sourceRange As range
        Dim fillRange As range

        Set sourceRange = Worksheets(1).Cells(rangeItem1.row + 1, rangeItem1.Column + 2)
        sourceRange.Select
        ActiveCell.FormulaR1C1 = "=RC[-2]-RC[-1]"

        Set fillRange = range(Worksheets(1).Cells(rangeItem1.row + 1, rangeItem1.Column + 2), _
                                Worksheets(1).Cells(rangeItem1.row + rangeItem1.rows.count - 1, rangeItem1.Column + 2))

        '此处根据选中的sourceRange进行fillRange的填充，fillRange必须包含sourceRange
        Selection.AutoFill Destination:=fillRange, Type:=xlFillDefault
    End Sub

    Private Function varianceValue(range As range) As Double
    '
    ' 求方差
    '
        Dim targetCellRange As range

        Set targetCellRange = Worksheets(1).Cells(range.row + range.rows.count, range.Column)
        targetCellRange.Select

        targetCellRange.FormulaR1C1 = "=SQRT(VAR(R[-22]C[0]:R[-1]C[0]))"

        '返回值
        varianceValue = targetCellRange.Value
    End Function
    ```




---
