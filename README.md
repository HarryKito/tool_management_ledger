# onetop_tool_management

Tool management project for Onetop.
    
FIXME:
> bug : 도구 _ 불출량 > 전체 수량 _ 현상 발생.

# TODO:
##  대표님 요구사항.
> 반납 時　기록은 남기되, 삭제는 하지 않음.  
>> 삭제버튼은 별도로 분류하자.   

> 반출기록, 담당자 -> (현장 책임자 , 반출자)로 나누기

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
