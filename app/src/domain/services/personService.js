import axios from "axios";

/**
 * API base URL.
 * Uses VITE_API_URL env var when available (Docker/production),
 * falls back to JSONPlaceholder for development.
 */
/* global __VITE_API_URL__ */
const API_BASE =
    (typeof __VITE_API_URL__ !== "undefined" && __VITE_API_URL__)
        ? __VITE_API_URL__
        : "https://jsonplaceholder.typicode.com";

/**
 * Fetch all users from the API.
 *
 * @async
 * @function fetchUsers
 * @returns {Promise<Array>} List of users
 * @throws {Error} Throws "SERVER_ERROR" if request fails
 */
export async function fetchUsers() {
    try {
        const response = await axios.get(`${API_BASE}/users`);
        const data = response.data;

        // Handle real API format ({users: [...]})
        if (data.users) {
            return data.users;
        }

        // Handle JSONPlaceholder format
        return data.map(u => ({
            firstName: u.name.split(' ')[0] || '',
            lastName: u.name.split(' ')[1] || '',
            email: u.email,
            birthDate: '',
            zip: u.address?.zipcode || '',
            city: u.address?.city || ''
        }));
    } catch (error) {
        throw new Error("SERVER_ERROR");
    }
}

/**
 * Create a new user via API.
 * Performs local email uniqueness check to simulate business validation.
 *
 * @async
 * @function createUser
 * @param {Object} person - User object to create
 * @param {Array<string>} existingEmails - List of already registered emails
 * @returns {Promise<Object>} Created user
 * @throws {Error} Throws "EMAIL_ALREADY_EXISTS" or "SERVER_ERROR"
 */
export async function createUser(person, existingEmails = []) {
    if (existingEmails.includes(person.email.toLowerCase())) {
        throw new Error("EMAIL_ALREADY_EXISTS");
    }

    try {
        const response = await axios.post(`${API_BASE}/users`, person);
        return response.data;
    } catch (error) {
        const status = error.response?.status;

        if (status === 400 && error.response.data?.message === "EMAIL_ALREADY_EXISTS") {
            throw new Error("EMAIL_ALREADY_EXISTS");
        }

        if (status >= 500 && status < 600) {
            throw new Error("SERVER_ERROR");
        }

        throw new Error("SERVER_ERROR");
    }
}
