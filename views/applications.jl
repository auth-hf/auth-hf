<extend src="layout.jl">
    <block name="body">
        <section class="hero is-bold is-dark">
            <include src="navbar.jl" />
            <div class="hero-body">
                <div class="container">
                    <h1 class="title">
                        <span class="icon">
                            <i class="fa fa-laptop"></i>
                        </span>
                        <span>&nbsp;&nbsp;Applications ({{ user.applications.length }})</span>
                    </h1>
                    <h2 class="subtitle">
                        Securely authenticate your users using the HackForums.net API.
                    </h2>
                </div>
            </div>
        </section>
        <section>
            <div class="container" style="padding-top: 1em;">
                <div if=user.apiKey != null class="button is-dark" id="showButton">
                    <span class="icon">
                        <i class="fa fa-plus"></i>
                    </span>
                    <span>Register new Application</span>
                </div>
                <br><br>

                <div if=user.apiKey == null class="notification">
                    You cannot register applications with Auth HF until you
                    <a href="/settings">add your HackForums.net API key</a>.
                    <br><br>
                    This is to ensure the security of all users.
                </div>

                <div if=user.applications.isEmpty class="notification">
                    You do not have any applications registered with Auth HF.
                </div>

                <div if=user.applications.isNotEmpty>
                    <div for-each=user.applications class="box">
                        <article class="media">
                            <div class="media-content">
                                <div class="content">
                                    <p>
                                        <strong>{{ item.name }}</strong>
                                        <br>
                                        {{ item.description }}
                                    </p>
                                </div>
                            </div>
                            <div class="media-right">
                                <a class="button is-dark" href="/applications/" + item.id>
                                    <span class="icon">
                                        <i class="fa fa-edit"></i>
                                    </span>
                                        <span>
                                        Edit
                                    </span>
                                </a>
                            </div>
                        </article>
                    </div>
                </div>
            </div>
        </section>

        <div class="modal" id="newApplicationModal">
            <div class="modal-background"></div>
            <div class="modal-card">
                <header class="modal-card-head">
                    <p class="modal-card-title">Register new Application</p>
                </header>
                <section class="modal-card-body">
                    <div class="notification is-warning">
                        Ensure you enter all fields correctly.
                        Applications cannot be modified.
                    </div>

                    <form action="/applications" id="newApplicationForm" method="post">
                        <div class="field">
                            <label class="label">Name</label>
                            <div class="control has-icons-left has-icons-right">
                                <input name="name" class="input" placeholder="Application Name" required>
                                <span class="icon is-small is-left">
                                  <i class="fa fa-laptop"></i>
                                </span>
                            </div>
                        </div>

                        <div class="field">
                            <div class="control">
                                <label class="label">Description</label>
                                <textarea name="description" class="textarea" placeholder="Briefly describe your application" rows="5" required></textarea>
                            </div>
                        </div>

                        <div class="field">
                            <div class="control">
                                <label class="label">
                                    Valid Redirect URI's
                                </label>
                                <textarea name="redirect_uris" class="textarea" placeholder="Separate with a comma (,)" rows="5" required></textarea>
                            </div>
                        </div>
                    </form>
                </section>
                <footer class="modal-card-foot">
                    <button id="submitButton" class="button is-dark">Submit</button>
                    <button id="cancelButton" class="button">Cancel</button>
                </footer>
            </div>
        </div>
    </block>

    <block name="js">
        <script src="/js/applications.js"></script>
    </block>
</extend>