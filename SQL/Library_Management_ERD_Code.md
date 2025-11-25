Table books {
  isbn varchar(50) [pk]
  book_title varchar(70)
  category varchar(20)
  rental_price float
  status varchar(5)
  author varchar(50)
  publisher varchar(50)
}

Table branch {
  branch_id varchar(30) [pk]
  manager_id varchar(6)
  branch_address varchar(20)
  contact_no varchar(20)
}

Table members {
  member_id varchar(20) [pk]
  member_name varchar(20)
  member_address varchar(20)
  reg_date date
}

Table employees {
  emp_id varchar(6) [pk]
  emp_name varchar(20)
  position varchar(10)
  salary numeric
  branch_id varchar(10)
}

Table issued_status {
  issued_id varchar(20) [pk]
  issued_member_id varchar(6)
  issued_book_name varchar(70)
  issued_date date
  issued_book_isbn varchar(20)
  issued_emp_id varchar(6)
}

Table return_status {
  return_id varchar(6) [pk]
  issued_id varchar(20)
  return_book_name varchar(70)
  return_date date
  return_book_isbn varchar(50)
}

Ref: employees.branch_id > branch.branch_id
Ref: issued_status.issued_member_id > members.member_id
Ref: issued_status.issued_book_isbn > books.isbn
Ref: issued_status.issued_emp_id > employees.emp_id
Ref: return_status.issued_id > issued_status.issued_id

Ref: return_status.return_book_isbn > books.isbn
