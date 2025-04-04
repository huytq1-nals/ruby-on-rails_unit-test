# TỔNG HỢP TEST CASES

## Khi không có đơn hàng tồn tại (order không tồn tại)  
  ➤ Hàm `process_orders` trả về `false` khi không tìm thấy đơn hàng.

## process_type_a(order, user_id)
### Test Cases:
- **TC-A01:** Khi tạo file CSV thành công với `amount <= 150`, file CSV được tạo và có 2 dòng: header + dữ liệu đơn hàng.
- **TC-A02:** Khi tạo file CSV thành công với `amount > 150`, file CSV chứa thêm dòng ghi chú `["", "", "", "", "Note", "High value order"]`.
- **TC-A03:** Khi `amount > 200`, trường `priority` được cập nhật thành `"high"`.
- **TC-A04:** Khi `amount <= 200`, trường `priority` được cập nhật thành `"low"`.
- **TC-A05:** Khi gặp lỗi khi lưu đơn hàng (`save!` raise `DatabaseException`), trạng thái đơn hàng được cập nhật thành `"db_error"` và không thay đổi `priority`.
- **TC-A06:** Khi xảy ra lỗi trong lúc ghi file CSV (`CSV.open` raise `StandardError`), trạng thái đơn hàng được cập nhật thành `"export_failed"`.
- **TC-A07:** Khi xử lý đơn hàng bị lỗi chung (`process_order` raise `StandardError`), `process_orders` trả về `false`.


## process_type_b(order, user_id)
### Test Cases:
- **TC-B01:** Khi API trả về `status: 'success'`, `data >= 50`, `amount < 100`, `flag: true`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"processed"`.
- **TC-B02:** Khi API trả về `status: 'success'`, `data >= 50`, `amount < 100`, `flag: false`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"processed"`.
- **TC-B03:** Khi API trả về `status: 'success'`, `data < 50`, `amount < 100`, `flag: true`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"pending"`.
- **TC-B04:** Khi API trả về `status: 'success'`, `data < 50`, `amount < 100`, `flag: false`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"pending"`.
- **TC-B05:** Khi API trả về `status: 'success'`, `data >= 50`, `amount > 100`, `flag: false`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"error"`.
- **TC-B06:** Khi API trả về `status: 'success'`, `data >= 50`, `amount > 100`, `flag: true`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"pending"`.
- **TC-B07:** Khi API trả về `status: 'error'`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"api_error"`.
- **TC-B08:** Khi `call_api` raise `ApiException`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"api_failure"`.
- **TC-B09:** Khi `amount > 200` và `priority = "low"`  
  ➤ Trường `priority` được cập nhật thành `"high"`.
- **TC-B10:** Khi `amount <= 200` và `priority = "high"`  
  ➤ Trường `priority` được cập nhật thành `"low"`.
- **TC-B11:** Khi `save!` raise `DatabaseException`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"db_error"`, `priority` không thay đổi.
- **TC-B12:** Khi `process_order` raise `StandardError`  
  ➤ Hàm `process_orders` trả về `false`.

## process_type_c(order, user_id)
### Test Cases:
- **TC-C01:** Khi `flag: true`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"completed"`.
- **TC-C02:** Khi `flag: false`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"in_progress"`.
- **TC-C03:** Khi `amount > 200` và `priority: "low"`  
  ➤ Trường `priority` được cập nhật thành `"high"`.
- **TC-C04:** Khi `amount <= 200` và `priority: "high"`  
  ➤ Trường `priority` được cập nhật thành `"low"`.
- **TC-C05:** Khi `save!` raise `DatabaseException`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"db_error"`, `priority` không thay đổi.
- **TC-C06:** Khi `process_order` raise `StandardError`  
  ➤ Hàm `process_orders` trả về `false`.


## process_type_other(order, user_id)
### Test Cases:
- **TC-X01:** Khi `order_type: 'X'`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"unknown_type"`.
- **TC-X02:** Khi `amount > 200` và `priority: "low"`  
  ➤ Trường `priority` được cập nhật thành `"high"`.
- **TC-X03:** Khi `amount <= 200` và `priority: "high"`  
  ➤ Trường `priority` được cập nhật thành `"low"`.
- **TC-X04:** Khi `save!` raise `DatabaseException`  
  ➤ Trạng thái đơn hàng được cập nhật thành `"db_error"`, `priority` không thay đổi.
- **TC-X05:** Khi `process_order` raise `StandardError`  
  ➤ Hàm `process_orders` trả về `false`.
