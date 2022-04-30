package models

type Request struct {
	UserId int64   `json:"user_id"`
	Phone  string  `json:"phone,omitempty"`
	Amount float64 `json:"amount,omitempty"`
}

type Response struct {
	ClientName string  `json:"client_name,omitempty" gorm:"column:p_client_name"`
	Phone      string  `json:"phone" gorm:"column:p_phone"`
	Status     bool    `json:"status,omitempty" gorm:"column:p_status"`
	Identified bool    `json:"identified,omitempty" gorm:"column:p_identified"`
	Balance    float64 `json:"balance,omitempty" gorm:"column:p_balance"`
	Count      int     `json:"count,omitempty" gorm:"column:p_count"`
	Sum        float64 `json:"sum,omitempty" gorm:"column:p_sum"`
	Code       int     `json:"code,omitempty" gorm:"column:p_code"`
	Message    string  `json:"reason,omitempty" gorm:"column:p_message"`
}
