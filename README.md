# onetop_tool_management

Tool management project for Onetop.

# Todo
    모든 수정 버튼마다 확인 (Alert Dialog 추가)
    직관적이게 도구사용기록 수정버튼(Text+) 추가
    사용기간 -> 불출일
    > 도구사용 내역 하위 리스트
        입고일 추가 입고일 != NULL
            색 변경 (직관성)
    
FIXME:
> bug : 도구 상세 목록 --> 잔여수량 (실제 데이터 미반영)

TODO:
> main, 첫 화면(도구 목록)에 현장명 리스트도 만들기.
>   추가기능도 여기에 삽입해도 좋을지도.

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
