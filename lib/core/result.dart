/// 예상 가능한 실패를 예외 대신 값으로 돌려주는 타입. (CODING_RULES §7)
sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
}

/// 성공 값.
final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);

  final T value;
}

/// 실패 사유.
final class Err<T, E> extends Result<T, E> {
  const Err(this.error);

  final E error;
}
