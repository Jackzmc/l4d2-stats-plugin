export class QueryConditionBuilder {
    #conditions: string[] = []
    #data: any[] = []

    push(condition: string, data: any) {
        this.#conditions.push(condition)
        this.#data.push(data)
    }

    #buildQuery() {
        if(this.#conditions.length === 0) return ""
        return this.#conditions.join(" AND ")
    }

    /**
     * Returns query conditions for use in existing WHERE
     * @returns [query, data array] 
     */
    build() {
        return [this.#buildQuery(), this.#data]
    }

    /**
     * Returns full WHERE clause, if any conditions or blank query
     * @returns [query, data array] 
     */
    buildFullWhere() {
        if(this.#data.length === 0) return ["", []]
        return ["WHERE " + this.#buildQuery(), this.#data]
    }
}