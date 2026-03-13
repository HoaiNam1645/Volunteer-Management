<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class DatLaiMatKhauRequest extends FormRequest
{

    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'ma_xac_thuc' => 'required|string',
            'password'    => 'required|min:6|max:255|confirmed',
        ];
    }

    public function messages()
    {
        return [
            'ma_xac_thuc.required' => 'Mã xác thực không được để trống.',
            'password.required'    => 'Mật khẩu mới không được để trống.',
            'password.min'         => 'Mật khẩu phải có ít nhất 6 ký tự.',
            'password.max'         => 'Mật khẩu không được quá 255 ký tự.',
            'password.confirmed'   => 'Xác nhận mật khẩu không khớp.',
        ];
    }
}
