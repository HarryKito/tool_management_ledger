# onetop_tool_management

Tool management project for Onetop.

# build for windows release

# Todo
    모든 수정 버튼마다 확인 (Alert Dialog 추가)
    직관적이게 도구사용기록 수정버튼(Text+) 추가
    사용기간 -> 불출일
    > 도구사용 내역 하위 리스트
        입고일 추가 입고일 != NULL
            색 변경 (직관성)
    
FIXME:
> bug : 도구 _ 불출량 > 전체 수량 _ 현상 발생.

# TODO:
##  대표님 요구사항.
> 반납 時　기록은 남기되, 삭제는 하지 않음.  
>> 삭제버튼은 별도로 분류하자.   

> 불출일  -> 반출일 , 반입일도 표시

> 비고란 추가 (비고란 DB ...)
# DB Table structure
### 도구 모델
|名|변수|
|--|--|
|품번|id|
|품명|name|
|수량|quantity|
|잔량|remainingQuantity|

### 도구 사용 기록모델
|名|변수|
|--|--|
|사용번호|id|
|품번|toolId|
|시작일|startDate|
|종료일|endDate|
|사용량|amount|
|사용처|siteName|
|관리자|siteMan|
