require 'test/unit'
require './kingoftime'

class TestKingoftime < Test::Unit::TestCase
  def setup
    @date_at = "2020-01-27"
    @in_time = "10:00"
    @leave_time = "19:00"
    @in_message = "in message"
    @leave_message = "leave message"
  end

  def teardown
  end

  def test_time_to_min
    min = time_to_min('00:55')
    assert_equal(55, min)

    min = time_to_min('01:55')
    assert_equal(115, min)
  end

  def test_is_overtime_reason_required
    assert_equal(false, is_overtime_reason_required('18:00'))
    assert_equal(false, is_overtime_reason_required('18:29'))
    assert_equal(false, is_overtime_reason_required('18:30'))
    assert_equal(true, is_overtime_reason_required('18:31'))
  end

  def test_get_overtime_reason
    assert_equal("too busy", get_overtime_reason)
    # todo 対話入力のテスト
  end

  def test_leave_time_make
    now = Time.mktime(2020, 1, 27, 19, 00)
    assert_equal("19:00", leave_time_make(now))

    now = Time.mktime(2020, 1, 27, 19, 14)
    assert_equal("19:00", leave_time_make(now))

    now = Time.mktime(2020, 1, 27, 19, 15)
    assert_equal("19:15", leave_time_make(now))

    now = Time.mktime(2020, 1, 27, 19, 59)
    assert_equal("19:45", leave_time_make(now))
  end
end
