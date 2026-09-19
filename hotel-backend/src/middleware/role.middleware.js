/**
 * requireRole('Admin', 'Manager') -> only those roles may pass.
 * Must run after the `authenticate` middleware (needs req.user.role).
 */
function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: "Not authenticated" });
    }
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: "You do not have permission to perform this action" });
    }
    next();
  };
}

module.exports = requireRole;
