package main

import "testing"

func TestAverage(t *testing.T) {
	v := Average([]float64{1, 2, 3, 5})
	if v != 2.5 {
		t.Error("Expected 2.5, got ", v)
	}
}
