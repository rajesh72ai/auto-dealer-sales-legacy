package com.autosales.modules.finance.entity;

import lombok.*;

import java.io.Serializable;
import java.util.Objects;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FiDealProductId implements Serializable {

    private String dealNumber;
    private Short productSeq;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        FiDealProductId that = (FiDealProductId) o;
        return Objects.equals(dealNumber, that.dealNumber)
                && Objects.equals(productSeq, that.productSeq);
    }

    @Override
    public int hashCode() {
        return Objects.hash(dealNumber, productSeq);
    }
}
