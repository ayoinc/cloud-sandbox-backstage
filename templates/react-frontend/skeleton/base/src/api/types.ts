export interface Item {
  id: string;
  name: string;
}

/** Thrown when the API answers with a status outside the 2xx range. */
export class ApiError extends Error {
  readonly status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}
