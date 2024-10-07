# onetop_tool_management

Tool management project for Onetop.

# build for windows release

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
