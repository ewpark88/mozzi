import 'package:meta/meta.dart';
import 'package:mozzi/core/json/json_reader.dart';
import 'package:mozzi/core/result.dart';

/// 화폐 종류 (GDD §7 화폐). 황금 해바라기씨는 프레스티지(v1.2)에서 추가한다.
enum Currency {
  /// 해바라기씨 (소프트): 비행·마을 생산으로 획득, 업그레이드에 사용.
  seed,

  /// 별사탕 (하드): 미션·출석·인앱결제로 획득, 뽑기·스킨·부활에 사용.
  candy,
}

/// 지출 실패 사유.
enum SpendError { insufficientFunds, invalidAmount }

/// 플레이어 지갑 (불변). 잔액은 음수가 될 수 없다.
@immutable
class Wallet {
  const Wallet({this.seeds = 0, this.candy = 0})
    : assert(seeds >= 0, 'seeds 는 0 이상'),
      assert(candy >= 0, 'candy 는 0 이상');

  /// 세이브에서 읽는다. 음수 잔액은 손상된 데이터로 보고 [JsonFormatError].
  factory Wallet.fromJson(JsonReader json) {
    final seeds = json.integer('seeds');
    final candy = json.integer('candy');
    if (seeds < 0 || candy < 0) {
      throw JsonFormatError(json.path, '음수 잔액 (seeds: $seeds, candy: $candy)');
    }
    return Wallet(seeds: seeds, candy: candy);
  }

  static const Wallet empty = Wallet();

  final int seeds;
  final int candy;

  int balance(Currency currency) => switch (currency) {
    Currency.seed => seeds,
    Currency.candy => candy,
  };

  Wallet _with(Currency currency, int value) => switch (currency) {
    Currency.seed => Wallet(seeds: value, candy: candy),
    Currency.candy => Wallet(seeds: seeds, candy: value),
  };

  /// [amount] (0 이상) 를 더한 지갑.
  Wallet add(Currency currency, int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', '0 이상이어야 한다');
    }
    return _with(currency, balance(currency) + amount);
  }

  bool canAfford(Currency currency, int amount) =>
      amount >= 0 && balance(currency) >= amount;

  /// [amount] 를 쓴 지갑. 잔액 부족·음수 금액이면 실패.
  Result<Wallet, SpendError> spend(Currency currency, int amount) {
    if (amount < 0) return const Err(SpendError.invalidAmount);
    if (!canAfford(currency, amount)) {
      return const Err(SpendError.insufficientFunds);
    }
    return Ok(_with(currency, balance(currency) - amount));
  }

  Map<String, int> toJson() => {'seeds': seeds, 'candy': candy};

  @override
  bool operator ==(Object other) =>
      other is Wallet && other.seeds == seeds && other.candy == candy;

  @override
  int get hashCode => Object.hash(seeds, candy);

  @override
  String toString() => 'Wallet(seeds: $seeds, candy: $candy)';
}
