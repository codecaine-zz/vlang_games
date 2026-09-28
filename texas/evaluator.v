module main

import rand

pub enum CardSuit {
	hearts
	diamonds
	clubs
	spades
}

pub struct Card {
pub mut:
	rank int // 2 .. 14 (11=J, 12=Q, 13=K, 14=A)
	suit CardSuit
}

pub fn generate_52_deck() []Card {
	mut deck := []Card{cap: 52}
	suits := [CardSuit.hearts, CardSuit.diamonds, CardSuit.clubs, CardSuit.spades]
	for s in suits {
		for r := 2; r <= 14; r++ {
			deck << Card{ rank: r, suit: s }
		}
	}
	return deck
}

pub fn shuffle_52_deck(mut deck []Card) {
	for i := deck.len - 1; i > 0; i-- {
		j := rand.int_in_range(0, i + 1) or { 0 }
		temp := deck[i]
		deck[i] = deck[j]
		deck[j] = temp
	}
}

pub enum HandRank {
	high_card = 1
	one_pair = 2
	two_pair = 3
	three_of_a_kind = 4
	straight = 5
	flush = 6
	full_house = 7
	four_of_a_kind = 8
	straight_flush = 9
	royal_flush = 10
}

pub struct HandScore {
pub mut:
	rank       HandRank
	name       string
	primary    int
	secondary  int
	kickers    []int
	score_val  i64 // Combined numeric score for easy comparison
}

pub fn evaluate_7card_hand(cards []Card) HandScore {
	if cards.len < 5 {
		return HandScore{ rank: .high_card, name: 'High Card', primary: 0, secondary: 0, score_val: 0 }
	}

	// 1. Check Flushes and Straight Flushes
	mut suit_counts := [0, 0, 0, 0]
	for c in cards {
		match c.suit {
			.hearts { suit_counts[0]++ }
			.diamonds { suit_counts[1]++ }
			.clubs { suit_counts[2]++ }
			.spades { suit_counts[3]++ }
		}
	}

	mut flush_suit := CardSuit.hearts
	mut has_flush := false
	for i, count in suit_counts {
		if count >= 5 {
			has_flush = true
			flush_suit = match i {
				0 { CardSuit.hearts }
				1 { CardSuit.diamonds }
				2 { CardSuit.clubs }
				else { CardSuit.spades }
			}
			break
		}
	}

	if has_flush {
		mut flush_ranks := []int{cap: 7}
		for c in cards {
			if c.suit == flush_suit {
				flush_ranks << c.rank
			}
		}
		sort_descending(mut flush_ranks)

		// Check straight in flush
		is_sf, sf_high := check_straight(flush_ranks)
		if is_sf {
			if sf_high == 14 {
				return HandScore{
					rank: .royal_flush
					name: 'Royal Flush'
					primary: 14
					score_val: compute_score(HandRank.royal_flush, 14, 0, [])
				}
			}
			return HandScore{
				rank: .straight_flush
				name: 'Straight Flush (${rank_to_str(sf_high)} High)'
				primary: sf_high
				score_val: compute_score(HandRank.straight_flush, sf_high, 0, [])
			}
		}
	}

	// Rank frequency map
	mut rank_counts := map[int]int{}
	for c in cards {
		rank_counts[c.rank] = rank_counts[c.rank] + 1
	}

	mut unique_ranks := []int{cap: 7}
	for r, _ in rank_counts {
		unique_ranks << r
	}
	sort_descending(mut unique_ranks)

	// 2. Four of a Kind
	for r in unique_ranks {
		if rank_counts[r] == 4 {
			mut kickers := []int{cap: 1}
			for kr in unique_ranks {
				if kr != r {
					kickers << kr
					break
				}
			}
			return HandScore{
				rank: .four_of_a_kind
				name: 'Four of a Kind (${rank_to_str(r)}s)'
				primary: r
				kickers: kickers
				score_val: compute_score(HandRank.four_of_a_kind, r, 0, kickers)
			}
		}
	}

	// 3. Full House (3 of a kind + pair or another 3 of a kind)
	mut three_ranks := []int{cap: 2}
	mut pair_ranks := []int{cap: 3}
	for r in unique_ranks {
		if rank_counts[r] == 3 {
			three_ranks << r
		} else if rank_counts[r] == 2 {
			pair_ranks << r
		}
	}

	if three_ranks.len >= 2 {
		return HandScore{
			rank: .full_house
			name: 'Full House (${rank_to_str(three_ranks[0])}s full of ${rank_to_str(three_ranks[1])}s)'
			primary: three_ranks[0]
			secondary: three_ranks[1]
			score_val: compute_score(HandRank.full_house, three_ranks[0], three_ranks[1], [])
		}
	} else if three_ranks.len == 1 && pair_ranks.len >= 1 {
		return HandScore{
			rank: .full_house
			name: 'Full House (${rank_to_str(three_ranks[0])}s full of ${rank_to_str(pair_ranks[0])}s)'
			primary: three_ranks[0]
			secondary: pair_ranks[0]
			score_val: compute_score(HandRank.full_house, three_ranks[0], pair_ranks[0], [])
		}
	}

	// 4. Flush
	if has_flush {
		mut flush_ranks := []int{cap: 7}
		for c in cards {
			if c.suit == flush_suit {
				flush_ranks << c.rank
			}
		}
		sort_descending(mut flush_ranks)
		top5 := flush_ranks[..5].clone()
		return HandScore{
			rank: .flush
			name: 'Flush (${rank_to_str(top5[0])} High)'
			primary: top5[0]
			kickers: top5[1..].clone()
			score_val: compute_score(HandRank.flush, top5[0], 0, top5[1..])
		}
	}

	// 5. Straight
	is_st, st_high := check_straight(unique_ranks)
	if is_st {
		return HandScore{
			rank: .straight
			name: 'Straight (${rank_to_str(st_high)} High)'
			primary: st_high
			score_val: compute_score(HandRank.straight, st_high, 0, [])
		}
	}

	// 6. Three of a Kind
	if three_ranks.len == 1 {
		mut kickers := []int{cap: 2}
		for r in unique_ranks {
			if r != three_ranks[0] {
				kickers << r
				if kickers.len == 2 {
					break
				}
			}
		}
		return HandScore{
			rank: .three_of_a_kind
			name: 'Three of a Kind (${rank_to_str(three_ranks[0])}s)'
			primary: three_ranks[0]
			kickers: kickers
			score_val: compute_score(HandRank.three_of_a_kind, three_ranks[0], 0, kickers)
		}
	}

	// 7. Two Pair
	if pair_ranks.len >= 2 {
		mut kickers := []int{cap: 1}
		for r in unique_ranks {
			if r != pair_ranks[0] && r != pair_ranks[1] {
				kickers << r
				break
			}
		}
		return HandScore{
			rank: .two_pair
			name: 'Two Pair (${rank_to_str(pair_ranks[0])}s and ${rank_to_str(pair_ranks[1])}s)'
			primary: pair_ranks[0]
			secondary: pair_ranks[1]
			kickers: kickers
			score_val: compute_score(HandRank.two_pair, pair_ranks[0], pair_ranks[1], kickers)
		}
	}

	// 8. One Pair
	if pair_ranks.len == 1 {
		mut kickers := []int{cap: 3}
		for r in unique_ranks {
			if r != pair_ranks[0] {
				kickers << r
				if kickers.len == 3 {
					break
				}
			}
		}
		return HandScore{
			rank: .one_pair
			name: 'One Pair of ${rank_to_str(pair_ranks[0])}s'
			primary: pair_ranks[0]
			kickers: kickers
			score_val: compute_score(HandRank.one_pair, pair_ranks[0], 0, kickers)
		}
	}

	// 9. High Card
	top5 := unique_ranks[..5].clone()
	return HandScore{
		rank: .high_card
		name: 'High Card (${rank_to_str(top5[0])})'
		primary: top5[0]
		kickers: top5[1..].clone()
		score_val: compute_score(HandRank.high_card, top5[0], 0, top5[1..])
	}
}

fn check_straight(ranks []int) (bool, int) {
	if ranks.len < 5 {
		return false, 0
	}
	mut distinct := ranks.clone()
	sort_descending(mut distinct)

	// Append 1 for wheel straight A-2-3-4-5
	if 14 in distinct {
		distinct << 1
	}

	for i := 0; i <= distinct.len - 5; i++ {
		mut is_seq := true
		for j := 0; j < 4; j++ {
			if distinct[i + j] - distinct[i + j + 1] != 1 {
				is_seq = false
				break
			}
		}
		if is_seq {
			return true, distinct[i]
		}
	}
	return false, 0
}

fn sort_descending(mut arr []int) {
	for i := 0; i < arr.len; i++ {
		for j := i + 1; j < arr.len; j++ {
			if arr[j] > arr[i] {
				tmp := arr[i]
				arr[i] = arr[j]
				arr[j] = tmp
			}
		}
	}
}

fn compute_score(rank HandRank, p int, s int, kickers []int) i64 {
	mut val := i64(rank) * 100_000_000_000
	val += i64(p) * 1_000_000_000
	val += i64(s) * 10_000_000
	for i, k in kickers {
		shift := match i {
			0 { i64(100_000) }
			1 { i64(1_000) }
			2 { i64(10) }
			else { i64(1) }
		}
		val += i64(k) * shift
	}
	return val
}

pub fn rank_to_str(r int) string {
	return match r {
		14 { 'Ace' }
		13 { 'King' }
		12 { 'Queen' }
		11 { 'Jack' }
		10 { '10' }
		else { '${r}' }
	}
}
