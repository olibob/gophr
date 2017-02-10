package main

// Average calculates the average of a list of floats
func Average(nums []float64) float64 {
	total := 0.0
	for _, x := range nums {
		total += x
	}
	return total / float64(len(nums))
}
