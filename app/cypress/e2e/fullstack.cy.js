describe("Fullstack E2E Tests - Real API", () => {

    beforeEach(() => {
        cy.visit("/");
    });

    it("should display pre-existing users from the database", () => {
        cy.get('[data-cy=user-count]').should("contain", "2");
        cy.get('[data-cy=user-list]').should("contain", "Sander");
        cy.get('[data-cy=user-list]').should("contain", "Jean");
    });

    it("should register a new user successfully via real API", () => {
        cy.get('[data-cy=nav-register]').click();
        cy.url().should("include", "/register");

        cy.get('[data-cy=firstName]').type("Alice");
        cy.get('[data-cy=lastName]').type("Martin");
        cy.get('[data-cy=email]').type("alice.martin@example.com");
        cy.get('[data-cy=birthDate]').type("1995-05-15");
        cy.get('[data-cy=zip]').type("75001");
        cy.get('[data-cy=city]').type("Paris");

        cy.get('[data-cy=submit]').click();

        cy.contains("Enregistré avec succès", { timeout: 10000 }).should('be.visible');

        cy.get('[data-cy=back-home]').click();
        cy.get('[data-cy=user-count]').should("contain", "3");
        cy.get('[data-cy=user-list]').should("contain", "Alice Martin");
    });

    it("should show error when registering with existing email", () => {
        cy.get('[data-cy=nav-register]').click();

        cy.get('[data-cy=firstName]').type("Test");
        cy.get('[data-cy=lastName]').type("User");
        cy.get('[data-cy=email]').type("sander@example.com");
        cy.get('[data-cy=birthDate]').type("1995-05-15");
        cy.get('[data-cy=zip]').type("75001");
        cy.get('[data-cy=city]').type("Paris");

        cy.get('[data-cy=submit]').click();

        cy.contains("Cet email est déjà utilisé").should("be.visible");
    });

});
